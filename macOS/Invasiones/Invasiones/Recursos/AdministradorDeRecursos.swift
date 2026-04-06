//
//  AdministradorDeRecursos.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of AdministradorDeRecursos.cs — singleton that loads and caches all game resources.
//  SDL_Surface → SKTexture, SDL_ttf → NSFont, SDL_mixer paths → strings for AVAudioEngine.
//

import SpriteKit

class AdministradorDeRecursos: NSObject, XMLParserDelegate {

    // MARK: - Singleton
    private static var s_instancia: AdministradorDeRecursos?

    static var Instancia: AdministradorDeRecursos {
        if s_instancia == nil { s_instancia = AdministradorDeRecursos() }
        return s_instancia!
    }

    // MARK: - Declarations
    /// Image cache indexed by id (Int) or name (String).
    private var m_imagenesPorId:     [Int: Superficie]    = [:]
    private var m_imagenesPorNombre: [String: Superficie] = [:]

    /// Resolved (absolute) paths read from res.xml.
    private(set) var pathsFuentes:    [String?] = []
    private(set) var pathsImagenes:   [String?] = []
    private(set) var pathsEscenarios: [String?] = []
    private(set) var pathsSonidos:    [String?] = []
    private(set) var pathsUnidades:   [String?] = []

    /// Loaded fonts (one per Definiciones.FNT variant).
    private(set) var fuentes: [Fuente?] = []

    /// Loaded sprites (Res.SPR_COUNT = 2).
    private(set) var sprites: [Sprite?] = []

    /// Loaded animations (Res.ANIM_COUNT = 13).
    private(set) var animaciones: [Animaciones?] = []

    /// Unit type templates (Res.UNIDAD_COUNT = 2).
    private(set) var tipoDeUnidades: [Unidad?] = []

    // MARK: - Initializer (privado)
    private override init() {}

    deinit { dispose() }

    func dispose() {
        fuentes.forEach { $0?.dispose() }
        fuentes.removeAll()
        m_imagenesPorId.removeAll()
        m_imagenesPorNombre.removeAll()
        AdministradorDeRecursos.s_instancia = nil
    }

    // MARK: - Load paths from res.xml

    @discardableResult
    func cargarPathsRecursos() -> Bool {
        guard let path = Utilidades.obtenerPath(Programa.ARCHIVO_XML_RECURSOS) else {
            Log.Instancia.error("No existe el archivo \(Programa.ARCHIVO_XML_RECURSOS).")
            return false
        }

        let parser = ResXMLParser()
        let xmlParser = XMLParser(contentsOf: URL(fileURLWithPath: path))
        xmlParser?.delegate = parser
        guard xmlParser?.parse() == true else {
            Log.Instancia.error("Error al parsear \(Programa.ARCHIVO_XML_RECURSOS).")
            return false
        }

        pathsFuentes    = parser.fuentes
        pathsImagenes   = parser.imagenes
        pathsEscenarios = parser.escenarios
        pathsSonidos    = parser.sonidos
        pathsUnidades   = parser.unidades

        let hayErrores = pathsFuentes.contains(where: { $0 == nil })
                      || pathsImagenes.contains(where: { $0 == nil })
        if hayErrores {
            Log.Instancia.error("Uno o más archivos no pudieron ser cargados.")
        }
        return !hayErrores
    }

    // MARK: - Images

    /// Gets (and caches) the image by relative or absolute file name.
    func obtenerImagen(_ nombre: String) -> Superficie? {
        if let cached = m_imagenesPorNombre[nombre] { return cached }
        // If it's already an absolute path that exists, use it directly.
        let path: String
        if nombre.hasPrefix("/") && FileManager.default.fileExists(atPath: nombre) {
            path = nombre
        } else {
            guard let resolved = Utilidades.obtenerPath(nombre) else { return nil }
            path = resolved
        }
        let sup = Superficie(path: path)
        m_imagenesPorNombre[nombre] = sup
        return sup
    }

    /// Gets (and caches) the image by ID (index into pathsImagenes).
    func obtenerImagen(_ id: Int) -> Superficie? {
        if let cached = m_imagenesPorId[id] { return cached }
        guard id < pathsImagenes.count, let path = pathsImagenes[id] else { return nil }
        let sup = Superficie(path: path)
        m_imagenesPorId[id] = sup
        return sup
    }

    /// Same as obtenerImagen(id) — in the original it loaded with an explicit alpha channel;
    /// in SpriteKit all PNG textures support alpha automatically.
    func obtenerImagenAlpha(_ id: Int) -> Superficie? {
        return obtenerImagen(id)
    }

    func obtenerCopiaImagen(_ nombre: String) -> Superficie? {
        guard let orig = obtenerImagen(nombre) else { return nil }
        return Superficie(copia: orig)
    }

    // MARK: - Fonts

    @discardableResult
    func cargarFuentes() -> Bool {
        guard fuentes.isEmpty else { return false }

        fuentes = Array(repeating: nil, count: Definiciones.FNT.TOTAL.rawValue)

        fuentes[Definiciones.FNT.SANS12.rawValue]   = Fuente(idFuente: Res.FNT_SANS,   tamanio: 12)
        fuentes[Definiciones.FNT.SANS14.rawValue]   = Fuente(idFuente: Res.FNT_SANS,   tamanio: 14)
        fuentes[Definiciones.FNT.SANS18.rawValue]   = Fuente(idFuente: Res.FNT_SANS,   tamanio: 18)
        fuentes[Definiciones.FNT.SANS20.rawValue]   = Fuente(idFuente: Res.FNT_SANS,   tamanio: 20)
        fuentes[Definiciones.FNT.SANS24.rawValue]   = Fuente(idFuente: Res.FNT_SANS,   tamanio: 24)
        fuentes[Definiciones.FNT.SANS28.rawValue]   = Fuente(idFuente: Res.FNT_SANS,   tamanio: 28)
        fuentes[Definiciones.FNT.LBLACK12.rawValue] = Fuente(idFuente: Res.FNT_LBLACK, tamanio: 12)
        fuentes[Definiciones.FNT.LBLACK14.rawValue] = Fuente(idFuente: Res.FNT_LBLACK, tamanio: 14)
        fuentes[Definiciones.FNT.LBLACK18.rawValue] = Fuente(idFuente: Res.FNT_LBLACK, tamanio: 18)
        fuentes[Definiciones.FNT.LBLACK20.rawValue] = Fuente(idFuente: Res.FNT_LBLACK, tamanio: 20)
        fuentes[Definiciones.FNT.LBLACK28.rawValue] = Fuente(idFuente: Res.FNT_LBLACK, tamanio: 28)

        return fuentes[Definiciones.FNT.SANS12.rawValue] != nil
    }

    // MARK: - Unit types

    func cargarTipoDeUnidades() {
        tipoDeUnidades = Array(repeating: nil, count: Res.UNIDAD_COUNT)
        for i in 0..<Res.UNIDAD_COUNT {
            let u = Unidad()
            u.leerUnidad(i)
            tipoDeUnidades[i] = u
        }
    }

    // MARK: - Sprites (reads <sprites> section of res.xml)

    @discardableResult
    func leerInfoSprites() -> Bool {
        guard let path = Utilidades.obtenerPath(Programa.ARCHIVO_XML_RECURSOS) else { return false }

        let parser = SpritesXMLParser()
        let xmlParser = XMLParser(contentsOf: URL(fileURLWithPath: path))
        xmlParser?.delegate = parser
        guard xmlParser?.parse() == true else { return false }

        sprites = parser.sprites
        return true
    }

    // MARK: - Animations (reads <anims> section of res.xml)

    @discardableResult
    func leerInfoAnimaciones() -> Bool {
        guard let path = Utilidades.obtenerPath(Programa.ARCHIVO_XML_RECURSOS) else { return false }

        let parser = AnimsXMLParser()
        let xmlParser = XMLParser(contentsOf: URL(fileURLWithPath: path))
        xmlParser?.delegate = parser
        guard xmlParser?.parse() == true else { return false }

        animaciones = parser.animaciones
        return true
    }
}

// MARK: - Internal res.xml parser

/// Parses res.xml and extracts the resolved paths for each section.
private class ResXMLParser: NSObject, XMLParserDelegate {

    var fuentes:    [String?] = Array(repeating: nil, count: Res.FNT_COUNT)
    var imagenes:   [String?] = Array(repeating: nil, count: Res.IMG_COUNT)
    var escenarios: [String?] = Array(repeating: nil, count: Res.TLS_COUNT + Res.MAP_COUNT)
    var sonidos:    [String?] = Array(repeating: nil, count: Res.SND_COUNT + Res.SFX_COUNT)
    var unidades:   [String?] = Array(repeating: nil, count: Res.UNIDAD_COUNT)

    // Parser state
    private enum Seccion { case ninguna, fuentes, imagenes, tilesets, mapas, sfx, unidades, anims }
    private var seccion: Seccion = .ninguna
    private var textoActual = ""
    private var enElementoHoja = false

    // Per-section counters
    private var iFuentes    = 0
    private var iImagenes   = 0
    private var iEscenarios = 0
    private var iSonidos    = 0
    private var iUnidades   = 0

    // For units (file="..." attribute)
    private var atributoFile: String?

    func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?,
                qualifiedName: String?, attributes: [String: String]) {
        switch name {
        case "fuentes":   seccion = .fuentes
        case "imagenes":  seccion = .imagenes
        case "tilesets":  seccion = .tilesets
        case "mapas":     seccion = .mapas
        case "sfx":       seccion = .sfx
        case "unidades":  seccion = .unidades
        case "anims":     seccion = .anims
        case "musica":    break  // ignore music section (was commented out in the original)
        case "res", "escenarios", "sonidos", "sprites", "sprite", "animpak",
             "animacion", "image": break
        default:
            // Leaf element within a known section
            if seccion == .unidades && name == "unidad" {
                atributoFile = attributes["file"]
                guardarUnidad()
            } else if seccion != .ninguna && seccion != .anims {
                textoActual = ""
                enElementoHoja = true
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if enElementoHoja { textoActual += string }
    }

    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?,
                qualifiedName: String?) {
        if enElementoHoja {
            let valor = textoActual.trimmingCharacters(in: .whitespacesAndNewlines)
            if !valor.isEmpty { guardarValor(valor) }
            textoActual = ""
            enElementoHoja = false
        }
        switch name {
        case "fuentes":  seccion = .ninguna
        case "imagenes": seccion = .ninguna
        case "tilesets": seccion = .ninguna
        case "mapas":    seccion = .ninguna
        case "sfx":      seccion = .ninguna
        case "unidades": seccion = .ninguna
        case "anims":    seccion = .ninguna
        default: break
        }
    }

    private func guardarValor(_ valor: String) {
        let path = Utilidades.obtenerPath(valor)
        switch seccion {
        case .fuentes:
            if iFuentes < fuentes.count { fuentes[iFuentes] = path; iFuentes += 1 }
        case .imagenes:
            if iImagenes < imagenes.count { imagenes[iImagenes] = path; iImagenes += 1 }
        case .tilesets, .mapas:
            if iEscenarios < escenarios.count { escenarios[iEscenarios] = path; iEscenarios += 1 }
        case .sfx:
            if iSonidos < sonidos.count { sonidos[iSonidos] = path; iSonidos += 1 }
        default: break
        }
    }

    private func guardarUnidad() {
        guard let file = atributoFile else { return }
        let path = Utilidades.obtenerPath(file)
        if iUnidades < unidades.count { unidades[iUnidades] = path; iUnidades += 1 }
        atributoFile = nil
    }
}

// MARK: - <sprites> parser for res.xml

private class SpritesXMLParser: NSObject, XMLParserDelegate {

    var sprites: [Sprite?] = Array(repeating: nil, count: Res.SPR_COUNT)

    private var enSprites   = false
    private var spriteIdx   = 0
    private var animaciones: [Animaciones] = []

    // Current attributes of the <image> element
    private var imgPath    = ""
    private var frameAncho = 0
    private var frameAlto  = 0
    private var ticks      = 0
    private var offsetX    = 0
    private var offsetY    = 0

    func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?,
                qualifiedName: String?, attributes: [String: String]) {
        switch name {
        case "sprites":
            enSprites = true; spriteIdx = 0

        case "sprite" where enSprites:
            animaciones = []

        case "image" where enSprites:
            imgPath    = Utilidades.obtenerPath(attributes["path"] ?? "") ?? ""
            frameAncho = Int(attributes["framewidth"]  ?? "0") ?? 0
            frameAlto  = Int(attributes["frameheight"] ?? "0") ?? 0
            ticks      = Int(attributes["frameticks"]  ?? "0") ?? 0
            offsetX    = Int(attributes["offsetX"]     ?? "0") ?? 0
            offsetY    = Int(attributes["offsetY"]     ?? "0") ?? 0
            let anim = Animaciones(idx: 0, path: imgPath, ticks: ticks,
                                   anchoFrame: frameAncho, altoFrame: frameAlto,
                                   offsetX: offsetX, offsetY: offsetY)
            animaciones.append(anim)

        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?,
                qualifiedName: String?) {
        if name == "sprite", enSprites {
            if spriteIdx < sprites.count {
                let spr = Sprite()
                spr.reservarSlots(animaciones.count)
                for (i, anim) in animaciones.enumerated() {
                    spr.agregarAnimacion(i, anim)
                }
                sprites[spriteIdx] = spr
                spriteIdx += 1
            }
        }
        if name == "sprites" { enSprites = false }
    }
}

// MARK: - <anims> parser for res.xml

private class AnimsXMLParser: NSObject, XMLParserDelegate {

    var animaciones: [Animaciones?] = Array(repeating: nil, count: Res.ANIM_COUNT)

    private var enAnims = false
    private var animIdx = 0

    func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?,
                qualifiedName: String?, attributes: [String: String]) {
        if name == "anims" { enAnims = true; animIdx = 0 }

        if name == "animacion", enAnims {
            let imgPath    = Utilidades.obtenerPath(attributes["imagepath"] ?? "") ?? ""
            let frameAncho = Int(attributes["framewidth"]  ?? "0") ?? 0
            let frameAlto  = Int(attributes["frameheight"] ?? "0") ?? 0
            let ticks      = Int(attributes["frameticks"]  ?? "0") ?? 0
            let offsetX    = Int(attributes["offsetX"]     ?? "0") ?? 0
            let offsetY    = Int(attributes["offsetY"]     ?? "0") ?? 0

            if animIdx < animaciones.count {
                animaciones[animIdx] = Animaciones(idx: 0, path: imgPath, ticks: ticks,
                                                   anchoFrame: frameAncho, altoFrame: frameAlto,
                                                   offsetX: offsetX, offsetY: offsetY)
                animIdx += 1
            }
        }
    }

    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?,
                qualifiedName: String?) {
        if name == "anims" { enAnims = false }
    }
}
