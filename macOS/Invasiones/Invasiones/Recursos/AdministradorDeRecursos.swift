// Recursos/AdministradorDeRecursos.swift
// Puerto de AdministradorDeRecursos.cs — singleton que carga y cachea todos los recursos del juego.
// SDL_Surface → SKTexture, SDL_ttf → NSFont, SDL_mixer paths → strings para AVAudioEngine.

import SpriteKit

class AdministradorDeRecursos: NSObject, XMLParserDelegate {

    // MARK: - Singleton
    private static var s_instancia: AdministradorDeRecursos?

    static var Instancia: AdministradorDeRecursos {
        if s_instancia == nil { s_instancia = AdministradorDeRecursos() }
        return s_instancia!
    }

    // MARK: - Declaraciones
    /// Caché de imágenes indexadas por id (Int) o nombre (String).
    private var m_imagenesPorId:     [Int: Superficie]    = [:]
    private var m_imagenesPorNombre: [String: Superficie] = [:]

    /// Paths resueltos (absolutos) leídos desde res.xml.
    private(set) var pathsFuentes:    [String?] = []
    private(set) var pathsImagenes:   [String?] = []
    private(set) var pathsEscenarios: [String?] = []
    private(set) var pathsSonidos:    [String?] = []
    private(set) var pathsUnidades:   [String?] = []

    /// Fuentes cargadas (una por cada variante de Definiciones.FNT).
    private(set) var fuentes: [Fuente?] = []

    // MARK: - Constructor (privado)
    private override init() {}

    deinit { dispose() }

    func dispose() {
        fuentes.forEach { $0?.dispose() }
        fuentes.removeAll()
        m_imagenesPorId.removeAll()
        m_imagenesPorNombre.removeAll()
        AdministradorDeRecursos.s_instancia = nil
    }

    // MARK: - Carga de paths desde res.xml

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

    // MARK: - Imágenes

    /// Obtiene (y cachea) la imagen por nombre de archivo relativo.
    func obtenerImagen(_ nombre: String) -> Superficie? {
        if let cached = m_imagenesPorNombre[nombre] { return cached }
        guard let path = Utilidades.obtenerPath(nombre) else { return nil }
        let sup = Superficie(path: path)
        m_imagenesPorNombre[nombre] = sup
        return sup
    }

    /// Obtiene (y cachea) la imagen por ID (índice en pathsImagenes).
    func obtenerImagen(_ id: Int) -> Superficie? {
        if let cached = m_imagenesPorId[id] { return cached }
        guard id < pathsImagenes.count, let path = pathsImagenes[id] else { return nil }
        let sup = Superficie(path: path)
        m_imagenesPorId[id] = sup
        return sup
    }

    /// Igual que obtenerImagen(id) — en el original cargaba con canal alpha explícito;
    /// en SpriteKit todas las texturas PNG soportan alpha automáticamente.
    func obtenerImagenAlpha(_ id: Int) -> Superficie? {
        return obtenerImagen(id)
    }

    func obtenerCopiaImagen(_ nombre: String) -> Superficie? {
        guard let orig = obtenerImagen(nombre) else { return nil }
        return Superficie(copia: orig)
    }

    // MARK: - Fuentes

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
}

// MARK: - Parser interno de res.xml

/// Parsea res.xml y extrae los paths resueltos de cada sección.
private class ResXMLParser: NSObject, XMLParserDelegate {

    var fuentes:    [String?] = Array(repeating: nil, count: Res.FNT_COUNT)
    var imagenes:   [String?] = Array(repeating: nil, count: Res.IMG_COUNT)
    var escenarios: [String?] = Array(repeating: nil, count: Res.TLS_COUNT + Res.MAP_COUNT)
    var sonidos:    [String?] = Array(repeating: nil, count: Res.SND_COUNT + Res.SFX_COUNT)
    var unidades:   [String?] = Array(repeating: nil, count: Res.UNIDAD_COUNT)

    // Estado del parser
    private enum Seccion { case ninguna, fuentes, imagenes, tilesets, mapas, sfx, unidades, anims }
    private var seccion: Seccion = .ninguna
    private var textoActual = ""
    private var enElementoHoja = false

    // Contadores por sección
    private var iFuentes    = 0
    private var iImagenes   = 0
    private var iEscenarios = 0
    private var iSonidos    = 0
    private var iUnidades   = 0

    // Para unidades (atributo file="...")
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
        case "musica":    break  // ignorar sección de música (estaba comentada en el original)
        case "res", "escenarios", "sonidos", "sprites", "sprite", "animpak",
             "animacion", "image", "anims": break
        default:
            // Elemento hoja dentro de una sección conocida
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
