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

    /// Resolved (absolute) paths read from res.xml.
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

    // MARK: - Load paths from res.xml

    @discardableResult
    func loadResourcePaths() -> Bool {
        guard let path = Utils.getPath(Program.RESOURCES_XML_FILE) else {
            Log.shared.error("No existe el archivo \(Program.RESOURCES_XML_FILE).")
            return false
        }

        let parser = ResXMLParser()
        let xmlParser = XMLParser(contentsOf: URL(fileURLWithPath: path))
        xmlParser?.delegate = parser
        guard xmlParser?.parse() == true else {
            Log.shared.error("Error al parsear \(Program.RESOURCES_XML_FILE).")
            return false
        }

        fontPaths = parser.fonts
        imagePaths = parser.images
        scenarioPaths = parser.scenarios
        soundPaths = parser.sounds
        unitPaths = parser.units

        let hasErrors = fontPaths.contains(where: { $0 == nil })
                      || imagePaths.contains(where: { $0 == nil })
        if hasErrors {
            Log.shared.error("Uno o más archivos no pudieron ser cargados.")
        }
        return !hasErrors
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

    @discardableResult
    func loadFonts() -> Bool {
        guard fonts.isEmpty else { return false }

        fonts = Array(repeating: nil, count: Definitions.FNT.TOTAL.rawValue)

        fonts[Definitions.FNT.SANS12.rawValue] = GameFont(fontId: Res.FNT_SANS, size: 12)
        fonts[Definitions.FNT.SANS14.rawValue] = GameFont(fontId: Res.FNT_SANS, size: 14)
        fonts[Definitions.FNT.SANS18.rawValue] = GameFont(fontId: Res.FNT_SANS, size: 18)
        fonts[Definitions.FNT.SANS20.rawValue] = GameFont(fontId: Res.FNT_SANS, size: 20)
        fonts[Definitions.FNT.SANS24.rawValue] = GameFont(fontId: Res.FNT_SANS, size: 24)
        fonts[Definitions.FNT.SANS28.rawValue] = GameFont(fontId: Res.FNT_SANS, size: 28)
        fonts[Definitions.FNT.LBLACK12.rawValue] = GameFont(fontId: Res.FNT_LBLACK, size: 12)
        fonts[Definitions.FNT.LBLACK14.rawValue] = GameFont(fontId: Res.FNT_LBLACK, size: 14)
        fonts[Definitions.FNT.LBLACK18.rawValue] = GameFont(fontId: Res.FNT_LBLACK, size: 18)
        fonts[Definitions.FNT.LBLACK20.rawValue] = GameFont(fontId: Res.FNT_LBLACK, size: 20)
        fonts[Definitions.FNT.LBLACK28.rawValue] = GameFont(fontId: Res.FNT_LBLACK, size: 28)

        return fonts[Definitions.FNT.SANS12.rawValue] != nil
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

    // MARK: - Sprites (reads <sprites> section of res.xml)

    @discardableResult
    func readSpriteInfo() -> Bool {
        guard let path = Utils.getPath(Program.RESOURCES_XML_FILE) else { return false }

        let parser = SpritesXMLParser()
        let xmlParser = XMLParser(contentsOf: URL(fileURLWithPath: path))
        xmlParser?.delegate = parser
        guard xmlParser?.parse() == true else { return false }

        sprites = parser.sprites
        return true
    }

    // MARK: - Animations (reads <anims> section of res.xml)

    @discardableResult
    func readAnimationInfo() -> Bool {
        guard let path = Utils.getPath(Program.RESOURCES_XML_FILE) else { return false }

        let parser = AnimsXMLParser()
        let xmlParser = XMLParser(contentsOf: URL(fileURLWithPath: path))
        xmlParser?.delegate = parser
        guard xmlParser?.parse() == true else { return false }

        animations = parser.animations
        return true
    }
}

// MARK: - Internal res.xml parser

/// Parses res.xml and extracts the resolved paths for each section.
private class ResXMLParser: NSObject, XMLParserDelegate {

    var fonts: [String?] = Array(repeating: nil, count: Res.FNT_COUNT)
    var images: [String?] = Array(repeating: nil, count: Res.IMG_COUNT)
    var scenarios: [String?] = Array(repeating: nil, count: Res.TLS_COUNT + Res.MAP_COUNT)
    var sounds: [String?] = Array(repeating: nil, count: Res.SND_COUNT + Res.SFX_COUNT)
    var units: [String?] = Array(repeating: nil, count: Res.UNIDAD_COUNT)

    // Parser state
    private enum Section { case none, fonts, images, tilesets, maps, sfx, units, anims }
    private var section: Section = .none
    private var currentText = ""
    private var inLeafElement = false

    // Per-section counters
    private var iFonts = 0
    private var iImages = 0
    private var iScenarios = 0
    private var iSounds = 0
    private var iUnits = 0

    // For units (file="..." attribute)
    private var fileAttr: String?

    func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?,
                qualifiedName: String?, attributes: [String: String]) {
        switch name {
        case "fuentes":   section = .fonts
        case "imagenes":  section = .images
        case "tilesets":  section = .tilesets
        case "mapas":     section = .maps
        case "sfx":       section = .sfx
        case "unidades":  section = .units
        case "anims":     section = .anims
        case "musica":    break  // ignore music section (was commented out in the original)
        case "res", "escenarios", "sonidos", "sprites", "sprite", "animpak",
             "animation", "image": break
        default:
            // Leaf element within a known section
            if section == .units && name == "unidad" {
                fileAttr = attributes["file"]
                saveUnit()
            } else if section != .none && section != .anims {
                currentText = ""
                inLeafElement = true
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inLeafElement { currentText += string }
    }

    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?,
                qualifiedName: String?) {
        if inLeafElement {
            let value = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !value.isEmpty { saveValue(value) }
            currentText = ""
            inLeafElement = false
        }
        switch name {
        case "fuentes":  section = .none
        case "imagenes": section = .none
        case "tilesets": section = .none
        case "mapas":    section = .none
        case "sfx":      section = .none
        case "unidades": section = .none
        case "anims":    section = .none
        default: break
        }
    }

    private func saveValue(_ value: String) {
        let path = Utils.getPath(value)
        switch section {
        case .fonts:
            if iFonts < fonts.count { fonts[iFonts] = path; iFonts += 1 }
        case .images:
            if iImages < images.count { images[iImages] = path; iImages += 1 }
        case .tilesets, .maps:
            if iScenarios < scenarios.count { scenarios[iScenarios] = path; iScenarios += 1 }
        case .sfx:
            if iSounds < sounds.count { sounds[iSounds] = path; iSounds += 1 }
        default: break
        }
    }

    private func saveUnit() {
        guard let file = fileAttr else { return }
        let path = Utils.getPath(file)
        if iUnits < units.count { units[iUnits] = path; iUnits += 1 }
        fileAttr = nil
    }
}

// MARK: - <sprites> parser for res.xml

private class SpritesXMLParser: NSObject, XMLParserDelegate {

    var sprites: [Sprite?] = Array(repeating: nil, count: Res.SPR_COUNT)

    private var inSprites = false
    private var spriteIdx = 0
    private var animations: [Animation] = []

    // Current attributes of the <image> element
    private var imgPath = ""
    private var frameAncho = 0
    private var frameAlto = 0
    private var ticks = 0
    private var offsetX = 0
    private var offsetY = 0

    func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?,
                qualifiedName: String?, attributes: [String: String]) {
        switch name {
        case "sprites":
            inSprites = true; spriteIdx = 0

        case "sprite" where inSprites:
            animations = []

        case "image" where inSprites:
            imgPath = Utils.getPath(attributes["path"] ?? "") ?? ""
            frameAncho = Int(attributes["framewidth"] ?? "0") ?? 0
            frameAlto = Int(attributes["frameheight"] ?? "0") ?? 0
            ticks = Int(attributes["frameticks"] ?? "0") ?? 0
            offsetX = Int(attributes["offsetX"] ?? "0") ?? 0
            offsetY = Int(attributes["offsetY"] ?? "0") ?? 0
            let anim = Animation(idx: 0, path: imgPath, ticks: ticks,
                                   anchoFrame: frameAncho, altoFrame: frameAlto,
                                   offsetX: offsetX, offsetY: offsetY)
            animations.append(anim)

        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?,
                qualifiedName: String?) {
        if name == "sprite", inSprites {
            if spriteIdx < sprites.count {
                let spr = Sprite()
                spr.reserveSlots(animations.count)
                for (i, anim) in animations.enumerated() {
                    spr.addAnimation(i, anim)
                }
                spr.load()
                sprites[spriteIdx] = spr
                spriteIdx += 1
            }
        }
        if name == "sprites" { inSprites = false }
    }
}

// MARK: - <anims> parser for res.xml

private class AnimsXMLParser: NSObject, XMLParserDelegate {

    var animations: [Animation?] = Array(repeating: nil, count: Res.ANIM_COUNT)

    private var inAnims = false
    private var animIdx = 0

    func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?,
                qualifiedName: String?, attributes: [String: String]) {
        if name == "anims" { inAnims = true; animIdx = 0 }

        if name == "animacion", inAnims {
            let imgPath = Utils.getPath(attributes["imagepath"] ?? "") ?? ""
            let frameAncho = Int(attributes["framewidth"] ?? "0") ?? 0
            let frameAlto = Int(attributes["frameheight"] ?? "0") ?? 0
            let ticks = Int(attributes["frameticks"] ?? "0") ?? 0
            let offsetX = Int(attributes["offsetX"] ?? "0") ?? 0
            let offsetY = Int(attributes["offsetY"] ?? "0") ?? 0

            if animIdx < animations.count {
                animations[animIdx] = Animation(idx: 0, path: imgPath, ticks: ticks,
                                                   anchoFrame: frameAncho, altoFrame: frameAlto,
                                                   offsetX: offsetX, offsetY: offsetY)
                animIdx += 1
            }
        }
    }

    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?,
                qualifiedName: String?) {
        if name == "anims" { inAnims = false }
    }
}
