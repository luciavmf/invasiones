//
//  ResourceManager.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of AdministradorDeRecursos.cs — singleton that loads and caches all game resources.
//  SDL_Surface → SKTexture, SDL_ttf → NSFont, SDL_mixer paths → strings for AVAudioEngine.
//

import SpriteKit

class ResourceManager {

    // MARK: - Singleton
    static let shared = ResourceManager()

    // MARK: - Declarations
    /// Image cache indexed by id (Int) or name (String).
    private var imageById: [Int: Surface] = [:]
    private var imageByName: [String: Surface] = [:]

    /// Resolved (absolute) paths read from res.json.
    private(set) var fontPaths: [String?] = []
    private(set) var imagePaths: [String?] = []
    private(set) var scenarioPaths: [String?] = []
    private(set) var soundPaths: [String?] = []
    private(set) var unitPaths: [String?] = []

    /// Loaded fonts (one per Definitions.FNT variant).
    private(set) var fonts: [GameFont?] = []

    /// Loaded sprites (Res.SPR_COUNT = 2).
    private(set) var sprites: [Sprite?] = []

    /// Loaded animations (Res.ANIM_COUNT = 13).
    private(set) var animations: [Animation?] = []

    /// Unit type templates (Res.UNIDAD_COUNT = 2).
    private(set) var unitTypes: [Unit?] = []

    // MARK: - Initializer (private)
    private init() {}

    func dispose() {
        fonts.forEach { $0?.dispose() }
        fonts.removeAll()
        imageById.removeAll()
        imageByName.removeAll()
    }

    // MARK: - Load paths from res.json

    func loadResourcePaths() throws {
        let res = try decodeResJSON()

        fontPaths = res.fuentes.map { Utils.getPath($0) }
        imagePaths = res.imagenes.map { Utils.getPath($0) }
        scenarioPaths = (res.escenarios.tilesets + res.escenarios.mapas).map { Utils.getPath($0) }
        soundPaths = res.sonidos.sfx.map { Utils.getPath($0) }
        unitPaths = res.unidades.map { Utils.getPath($0.file) }

        let hasErrors = fontPaths.contains(where: { $0 == nil })
                      || imagePaths.contains(where: { $0 == nil })
        if hasErrors {
            throw GameError.invalidResource("Uno o más archivos no pudieron ser cargados.")
        }
    }

    // MARK: - Images

    /// Gets (and caches) the image by relative or absolute file name.
    func getImage(_ name: String) -> Surface? {
        if let cached = imageByName[name] { return cached }
        // If it's already an absolute path that exists, use it directly.
        let path: String
        if name.hasPrefix("/") && FileManager.default.fileExists(atPath: name) {
            path = name
        } else {
            guard let resolved = Utils.getPath(name) else { return nil }
            path = resolved
        }
        let sup = Surface(path: path)
        imageByName[name] = sup
        return sup
    }

    /// Gets (and caches) the image by ID (index into imagePaths).
    func getImage(_ id: Int) -> Surface? {
        if let cached = imageById[id] { return cached }
        guard id < imagePaths.count, let path = imagePaths[id] else { return nil }
        let sup = Surface(path: path)
        imageById[id] = sup
        return sup
    }

    /// Same as getImage(id) — in the original it loaded with an explicit alpha channel;
    /// in SpriteKit all PNG textures support alpha automatically.
    func getAlphaImage(_ id: Int) -> Surface? {
        return getImage(id)
    }

    func getCopyOfImage(_ name: String) -> Surface? {
        guard let orig = getImage(name) else { return nil }
        return Surface(copia: orig)
    }

    // MARK: - Fonts

    func loadFonts() throws {
        guard fonts.isEmpty else { return }

        fonts = Array(repeating: nil, count: FontIndex.total.rawValue)

        fonts[FontIndex.sans12.rawValue] = GameFont(fontId: Res.FNT_SANS, size: 12)
        fonts[FontIndex.sans14.rawValue] = GameFont(fontId: Res.FNT_SANS, size: 14)
        fonts[FontIndex.sans18.rawValue] = GameFont(fontId: Res.FNT_SANS, size: 18)
        fonts[FontIndex.sans20.rawValue] = GameFont(fontId: Res.FNT_SANS, size: 20)
        fonts[FontIndex.sans24.rawValue] = GameFont(fontId: Res.FNT_SANS, size: 24)
        fonts[FontIndex.sans28.rawValue] = GameFont(fontId: Res.FNT_SANS, size: 28)
        fonts[FontIndex.lblack12.rawValue] = GameFont(fontId: Res.FNT_LBLACK, size: 12)
        fonts[FontIndex.lblack14.rawValue] = GameFont(fontId: Res.FNT_LBLACK, size: 14)
        fonts[FontIndex.lblack18.rawValue] = GameFont(fontId: Res.FNT_LBLACK, size: 18)
        fonts[FontIndex.lblack20.rawValue] = GameFont(fontId: Res.FNT_LBLACK, size: 20)
        fonts[FontIndex.lblack28.rawValue] = GameFont(fontId: Res.FNT_LBLACK, size: 28)

        if fonts[FontIndex.sans12.rawValue] == nil {
            throw GameError.invalidResource("No se pudo cargar la fuente SANS12.")
        }
    }

    // MARK: - Unit types

    func loadUnitTypes() {
        unitTypes = Array(repeating: nil, count: Res.UNIDAD_COUNT)
        for i in 0..<Res.UNIDAD_COUNT {
            let u = Unit()
            u.readUnit(i)
            unitTypes[i] = u
        }
    }

    // MARK: - Sprites (reads "sprites" section of res.json)

    func readSpriteInfo() throws {
        let res = try decodeResJSON()

        sprites = Array(repeating: nil, count: Res.SPR_COUNT)
        for (i, sprJSON) in res.sprites.prefix(Res.SPR_COUNT).enumerated() {
            let anims = sprJSON.animpaks.map { pak -> Animation in
                let img = pak.image
                let path = Utils.getPath(img.path) ?? ""
                return Animation(idx: 0, path: path, ticks: img.frameticks,
                                 frameWidth: img.framewidth, frameHeight: img.frameheight,
                                 offsetX: img.offsetX, offsetY: img.offsetY)
            }
            let spr = Sprite()
            spr.reserveSlots(anims.count)
            for (j, anim) in anims.enumerated() {
                spr.addAnimation(i: j, anim: anim)
            }
            try? spr.load()
            sprites[i] = spr
        }
    }

    // MARK: - Animations (reads "anims" section of res.json)

    func readAnimationInfo() throws {
        let res = try decodeResJSON()

        animations = Array(repeating: nil, count: Res.ANIM_COUNT)
        for (i, animJSON) in res.anims.prefix(Res.ANIM_COUNT).enumerated() {
            let path = Utils.getPath(animJSON.imagepath) ?? ""
            animations[i] = Animation(idx: 0, path: path, ticks: animJSON.frameticks,
                                      frameWidth: animJSON.framewidth, frameHeight: animJSON.frameheight,
                                      offsetX: animJSON.offsetX, offsetY: animJSON.offsetY)
        }
    }

    // MARK: - Private JSON decoding

    private func decodeResJSON() throws -> ResJSON {
        guard let path = Utils.getPath(ResourcePath.resourcesPath) else {
            throw GameError.fileNotFound("No existe el archivo \(ResourcePath.resourcesPath).")
        }
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        do {
            return try JSONDecoder().decode(ResJSON.self, from: data)
        } catch {
            throw GameError.parsingFailed("ResourceManager: failed to parse \(ResourcePath.resourcesPath): \(error).")
        }
    }
}

// MARK: - res.json Codable model

private struct ResJSON: Decodable {

    struct Escenarios: Decodable {
        let tilesets: [String]
        let mapas: [String]
    }

    struct Sonidos: Decodable {
        let sfx: [String]
    }

    struct Unidad: Decodable {
        let name: String
        let file: String
    }

    struct ImagenAnim: Decodable {
        let path: String
        let framewidth: Int
        let frameheight: Int
        let frameticks: Int
        let offsetX: Int
        let offsetY: Int
    }

    struct Animpak: Decodable {
        let name: String
        let image: ImagenAnim
    }

    struct SpriteJSON: Decodable {
        let name: String
        let animpaks: [Animpak]
    }

    struct AnimJSON: Decodable {
        let name: String
        let imagepath: String
        let framewidth: Int
        let frameheight: Int
        let offsetX: Int
        let offsetY: Int
        let frameticks: Int
    }

    let fuentes: [String]
    let escenarios: Escenarios
    let sonidos: Sonidos
    let imagenes: [String]
    let unidades: [Unidad]
    let sprites: [SpriteJSON]
    let anims: [AnimJSON]
}
