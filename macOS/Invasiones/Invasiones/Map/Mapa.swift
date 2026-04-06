// Map/Mapa.swift
// Puerto de Mapa.cs — carga y renderiza un mapa isométrico en formato TMX (Tiled).
// Soporta múltiples capas, tilesets y scroll de cámara por mouse.

import Foundation

class Mapa {

    // MARK: - Constantes
    private let NRO_MAXIMO_DE_CAPAS = 8
    private let CAPA_INFO           = 8

    // MARK: - Índices de capas (leídos del XML)
    private(set) var CAPA_TERRENO:               Int = 0
    private var CAPA_OBSTACULOS:                 Int = 0
    private var CAPA_UNIDADES_JUGADOR:           Int = 0
    private var CAPA_POSICIONES_INVALIDADAS:     Int = 0

    static let TILE_VISIBLE: Int = 1

    // MARK: - Datos del mapa
    /// `m_mapa[capa][i][j]` = tile ID (Int16).
    private var m_mapa: [[[Int16]]] = []           // [capa][col][fila]
    private var m_nombresCapas: [String: Int] = [:]
    private var m_mapaCargado  = false
    private var m_numeroMaximoDeCapas = 0

    private var m_altoEnTiles:          Int = 0
    private var m_altoEnTilesMapaFisico: Int = 0
    private var m_anchoEnTiles:         Int = 0
    private var m_anchoEnTilesMapaFisico: Int = 0

    private(set) var tileAncho:      Int = 0
    private(set) var tileAlto:       Int = 0
    private(set) var tileFisicoAncho: Int = 0
    private(set) var tileFisicoAlto:  Int = 0

    private var m_tilesets:      [Tileset?] = Array(repeating: nil, count: Res.TLS_COUNT)
    private var m_tilesetMaximo: Int = 0

    private static var m_tilesetDebug: Tileset?

    // MARK: - Mouse en tile
    private var m_tileMouse:      (x: Int, y: Int) = (0, 0)
    private var m_tileChicoMouse: (x: Int, y: Int) = (0, 0)

    // MARK: - Mapa físico (tiles pequeños, x2 de resolución)
    private(set) var capaTilesFisicos:  [[Int16]] = []  // [col * 2][fila * 2]
    var capaTilesVisibles: [[Int16]] = []

    // MARK: - Imagen de tile gris (debug / selección semitransparente)
    private var m_imagenTileGris: Superficie?

    // MARK: - Cámara
    private let m_camara: Camara

    // MARK: - Properties públicas
    var alto:      Int { m_altoEnTiles }
    var ancho:     Int { m_anchoEnTiles }
    var altoMapaFisico:  Int { m_altoEnTilesMapaFisico }
    var anchoMapaFisico: Int { m_anchoEnTilesMapaFisico }

    var tileBajoMouse:      (x: Int, y: Int) { m_tileMouse }
    var tileChicoMouse:     (x: Int, y: Int) { m_tileChicoMouse }

    var capaUnidades: [[Int16]] {
        guard CAPA_UNIDADES_JUGADOR < m_mapa.count else { return [] }
        return m_mapa[CAPA_UNIDADES_JUGADOR]
    }
    var capaObstaculos: [[Int16]] {
        guard CAPA_OBSTACULOS < m_mapa.count else { return [] }
        return m_mapa[CAPA_OBSTACULOS]
    }
    var capaEdificios: [[Int16]] {
        guard CAPA_POSICIONES_INVALIDADAS < m_mapa.count else { return [] }
        return m_mapa[CAPA_POSICIONES_INVALIDADAS]
    }
    var capaTerreno: [[Int16]] {
        guard CAPA_TERRENO < m_mapa.count else { return [] }
        return m_mapa[CAPA_TERRENO]
    }
    var tilesets: [Tileset?] { m_tilesets }

    // MARK: - Constructor
    init(camara: Camara) {
        m_camara = camara
    }

    // MARK: - Carga

    @discardableResult
    func cargar(_ mapId: Int) -> Bool {
        guard mapId >= Res.TLS_COUNT, mapId < Res.TLS_COUNT + Res.MAP_COUNT else {
            Log.Instancia.error("Mapa ID \(mapId) inválido.")
            return false
        }
        let paths = AdministradorDeRecursos.Instancia.pathsEscenarios
        guard mapId < paths.count, let mapPath = paths[mapId] else {
            Log.Instancia.error("No hay path para el mapa \(mapId).")
            return false
        }

        m_tilesetMaximo = 0
        m_numeroMaximoDeCapas = 0
        m_mapa = []
        m_nombresCapas = [:]

        guard leerInfoMapa(mapPath) else { return false }
        guard leerTilesets(mapPath, paths: paths) else { return false }
        guard leerCapas(mapPath) else { return false }

        cargarCapaInfo(paths: paths)
        m_mapaCargado = true
        return true
    }

    // MARK: - Dibujo

    /// Dibuja la capa `layer` en el Video dado usando la cámara actual.
    @discardableResult
    func dibujarCapa(_ g: Video, _ layer: Int) -> Bool {
        guard layer < m_numeroMaximoDeCapas, layer >= 0 else { return false }
        guard m_mapaCargado else { return false }

        let oldClip = g.obtenerClip()
        g.setearClip(m_camara.inicioX, m_camara.inicioY, m_camara.ancho, m_camara.alto)

        var cambio = true
        let p = calcularPrimerTileAPintar(m_camara.X, m_camara.Y)
        var XX = p.x, YY = p.y

        var posicionInicioX = m_camara.inicioX + (((XX - YY) * tileAncho) >> 1) + m_camara.X
        var posicionInicioY = m_camara.inicioY + (((XX + YY) * tileAlto)  >> 1) + m_camara.Y

        while posicionInicioY <= (m_camara.alto + m_camara.inicioY) {
            var tileX = 0
            var i = XX, j = YY
            while (tileX * tileAncho + posicionInicioX) <= (m_camara.inicioX + m_camara.ancho) && j >= 0 {
                if i < m_altoEnTiles && i >= 0 && j < m_anchoEnTiles && j >= 0 {
                    let tileId = Int(m_mapa[layer][i][j])
                    if tileId != 0, let ts = obtenerTileset(tileId) {
                        let localId = tileId - Int(ts.primerGid)
                        let rect = ts.obtenerRectanguloDelTile(localId)
                        g.dibujar(ts.imagen, rect.x, rect.y, rect.w, rect.h,
                                  tileX * tileAncho + posicionInicioX, posicionInicioY)
                    }
                }
                tileX += 1; i += 1; j -= 1
            }

            posicionInicioY += tileAlto >> 1

            if cambio {
                XX += 1; posicionInicioX += tileAncho >> 1; cambio = false
            } else {
                YY += 1; posicionInicioX -= tileAncho >> 1; cambio = true
            }
        }

        g.setearClip(oldClip.x, oldClip.y, oldClip.w, oldClip.h)
        return true
    }

    // MARK: - Tile Chico (fog-of-war)

    /// Dibuja un tile pequeño (mapa físico) en la posición isométrica correspondiente.
    /// Si `semiTransparente` es true dibuja el tile gris semitransparente (fog-of-war).
    func dibujarTileChico(_ g: Video, _ i: Int, _ j: Int, _ semiTransparente: Bool) {
        guard i >= 0, j >= 0, i < m_altoEnTilesMapaFisico, j < m_anchoEnTilesMapaFisico else { return }

        let posX = m_camara.inicioX + (((i - j) * tileAncho / 2) >> 1) + m_camara.X + tileAncho / 4
        let posY = m_camara.inicioY + (((i + j) * tileAlto  / 2) >> 1) + m_camara.Y

        if semiTransparente {
            if m_imagenTileGris == nil {
                m_imagenTileGris = AdministradorDeRecursos.Instancia.obtenerImagen(Res.IMG_TILE_GRIS)
            }
            g.dibujar(m_imagenTileGris, 0, 0, 32, 16, posX, posY)
        }
    }

    // MARK: - Actualización (scroll de cámara)

    func actualizar() {
        guard m_mapaCargado else { return }

        let mx = Int(Mouse.Instancia.X)
        let my = Int(Mouse.Instancia.Y)

        if mx < m_camara.borde {
            if m_camara.X + m_camara.velocidad <= (m_anchoEnTiles * tileAncho) / 2 {
                let p = calcularPrimerTileAPintar(m_camara.X, m_camara.Y)
                if p.x < -13 {
                    m_camara.Y -= m_camara.velocidad / 2
                } else {
                    let p2 = calcularPrimerTileAPintar(m_camara.X, m_camara.Y - m_camara.alto)
                    if p2.y > m_altoEnTiles + 13 { m_camara.Y += m_camara.velocidad / 2 }
                }
                m_camara.X += m_camara.velocidad
            }
        }

        if my > m_camara.alto - m_camara.borde {
            if (m_camara.Y - m_camara.velocidad) >= (m_camara.alto - m_altoEnTiles * tileAlto) &&
               m_camara.Y - m_camara.velocidad <= 0 {
                let p = calcularPrimerTileAPintar(m_camara.X, m_camara.Y - m_camara.alto)
                if p.y > m_altoEnTiles + 13 {
                    m_camara.Y -= m_camara.velocidad / 2
                    m_camara.X -= m_camara.velocidad
                } else {
                    let p2 = calcularPrimerTileAPintar(m_camara.X - m_camara.ancho, m_camara.Y - m_camara.alto)
                    if p2.x > m_anchoEnTiles + 13 {
                        m_camara.Y -= m_camara.velocidad / 2
                        m_camara.X += m_camara.velocidad
                    } else {
                        m_camara.Y -= m_camara.velocidad
                    }
                }
            }
        }

        if my < m_camara.borde {
            if m_camara.Y + m_camara.velocidad <= 0 {
                let p = calcularPrimerTileAPintar(m_camara.X, m_camara.Y)
                if p.x < -13 {
                    m_camara.X -= m_camara.velocidad
                    m_camara.Y += m_camara.velocidad / 2
                } else {
                    let p2 = calcularPrimerTileAPintar(m_camara.X - m_camara.ancho, m_camara.Y)
                    if p2.y < -13 {
                        m_camara.X += m_camara.velocidad
                        m_camara.Y += m_camara.velocidad / 2
                    } else {
                        m_camara.Y += m_camara.velocidad
                    }
                }
            }
        }

        if mx > m_camara.ancho - m_camara.borde {
            let p = calcularPrimerTileAPintar(m_camara.X - m_camara.ancho, m_camara.Y)
            if (m_camara.X - m_camara.ancho - m_camara.velocidad + tileAncho)
                >= -(m_anchoEnTiles * tileAncho) / 2 ||
               (m_camara.X - m_camara.velocidad) > 0 {
                if p.y < -13 {
                    m_camara.Y -= m_camara.velocidad / 2
                } else {
                    let p2 = calcularPrimerTileAPintar(m_camara.X - m_camara.ancho, m_camara.Y - m_camara.alto)
                    if p2.x > m_altoEnTiles + 13 { m_camara.Y += m_camara.velocidad / 2 }
                }
                m_camara.X -= m_camara.velocidad
            }
        }

        actualizarCoordenadasDelMouse()
    }

    // MARK: - Consultas públicas

    func obtenerTileset(_ tileId: Int) -> Tileset? {
        var resultado: Tileset? = nil
        for i in 0..<m_tilesetMaximo {
            if let ts = m_tilesets[i], tileId >= Int(ts.primerGid) {
                resultado = ts
            }
        }
        return resultado
    }

    func esPosicionCaminable(_ x: Int, _ y: Int) -> Bool {
        guard x >= 0, y >= 0,
              x < m_anchoEnTiles * 2, y < m_altoEnTiles * 2,
              x < capaTilesFisicos.count,
              y < capaTilesFisicos[x].count else { return false }
        let id = Int(capaTilesFisicos[x][y])
        return id == Res.TLS_PASTO || id == Res.TLS_TIERRA
    }

    func invalidarTile(_ x: Int, _ y: Int) {
        guard x >= 0, y >= 0,
              x + 1 < m_anchoEnTiles * 2,
              y + 1 < m_altoEnTiles * 2 else { return }
        let v = Int16(Res.TLS_ARBOLES)
        capaTilesFisicos[x][y]         = v
        capaTilesFisicos[x + 1][y]     = v
        capaTilesFisicos[x + 1][y + 1] = v
        capaTilesFisicos[x][y + 1]     = v
    }

    // MARK: - Privados

    private func calcularPrimerTileAPintar(_ x: Int, _ y: Int) -> (x: Int, y: Int) {
        let a = tileAlto > 0 ? -y / tileAlto : 0
        var b = tileAncho > 0 ? x / tileAncho : 0
        if x > 0 { b += 1 }
        return (a - b - 2, a + b - 1)
    }

    private func actualizarCoordenadasDelMouse() {
        guard m_mapaCargado else { return }
        let p = calcularPosicionDelTileEnXY(Int(Mouse.Instancia.X), Int(Mouse.Instancia.Y))
        m_tileMouse = p
    }

    private func calcularPosicionDelTileEnXY(_ x: Int, _ y: Int) -> (x: Int, y: Int) {
        guard tileAlto > 0, tileAncho > 0 else { return (0, 0) }
        let a = (y - m_camara.Y - m_camara.inicioY) / tileAlto
        let b: Int
        if x - m_camara.X > 0 {
            b = (x - m_camara.X - m_camara.inicioX) / tileAncho
        } else {
            b = (x - m_camara.X - m_camara.inicioX - tileAncho) / tileAncho
        }
        m_tileChicoMouse = (a + b, a - b)  // aproximación
        return (a + b, a - b)
    }

    // MARK: - Carga interna del TMX

    private func leerInfoMapa(_ path: String) -> Bool {
        guard let parser = XMLParser(contentsOf: URL(fileURLWithPath: path)) else { return false }
        let d = MapInfoDelegate()
        parser.delegate = d
        guard parser.parse() else { return false }
        guard d.orientacion == "isometric" else {
            Log.Instancia.error("Mapa: orientación no isométrica."); return false
        }
        m_anchoEnTiles = d.ancho;  m_anchoEnTilesMapaFisico = d.ancho * 2
        m_altoEnTiles  = d.alto;   m_altoEnTilesMapaFisico  = d.alto  * 2
        tileAncho = d.tileAncho;   tileFisicoAncho = d.tileAncho / 2
        tileAlto  = d.tileAlto;    tileFisicoAlto  = d.tileAlto  / 2
        m_camara.X = ((d.tileCamaraJ - d.tileCamaraI) * tileAncho) >> 1
        m_camara.Y = -((d.tileCamaraJ + d.tileCamaraI) * tileAlto) >> 1
        return true
    }

    private func leerTilesets(_ mapPath: String, paths: [String?]) -> Bool {
        guard let parser = XMLParser(contentsOf: URL(fileURLWithPath: mapPath)) else { return false }
        let base = (mapPath as NSString).deletingLastPathComponent
        let d = TilesetRefDelegate(base: base, paths: paths, mapa: self)
        parser.delegate = d
        return parser.parse()
    }

    private func leerCapas(_ path: String) -> Bool {
        guard let parser = XMLParser(contentsOf: URL(fileURLWithPath: path)) else { return false }
        let d = LayerDelegate(mapa: self)
        parser.delegate = d
        return parser.parse()
    }

    private func cargarCapaInfo(paths: [String?]) {
        if Mapa.m_tilesetDebug == nil {
            let ts = Tileset()
            if let p = paths[Res.TLS_DEBUG] { ts.cargar(p) }
            Mapa.m_tilesetDebug = ts
        }

        // Expando el mapa a la capa INFO (CAPA_INFO = 8)
        while m_mapa.count <= CAPA_INFO {
            m_mapa.append(Array(repeating: Array(repeating: 0, count: m_altoEnTiles),
                                count: m_anchoEnTiles))
        }

        // Inicializo el mapa físico (resolución doble)
        capaTilesFisicos = Array(repeating: Array(repeating: 0, count: m_altoEnTiles * 2),
                                 count: m_anchoEnTiles * 2)

        for capa in 0..<m_numeroMaximoDeCapas {
            for i in 0..<m_anchoEnTiles {
                for j in 0..<m_altoEnTiles {
                    if let ts = obtenerTileset(Int(m_mapa[capa][i][j])),
                       ts.id != Int16(Res.TLS_UNIDADES) {
                        let tsId = ts.id
                        m_mapa[CAPA_INFO][i][j] = tsId
                        let ci = i * 2, cj = j * 2
                        if ci + 1 < capaTilesFisicos.count && cj + 1 < capaTilesFisicos[ci].count {
                            capaTilesFisicos[ci][cj]     = tsId
                            capaTilesFisicos[ci][cj + 1] = tsId
                            capaTilesFisicos[ci + 1][cj] = tsId
                            capaTilesFisicos[ci + 1][cj + 1] = tsId
                        }
                    }
                }
            }
        }
        PathFinder.Instancia.cargarMapa(self)
    }

    // MARK: - Helpers llamados desde los delegates

    fileprivate func agregarNombreCapa(_ nombre: String, _ index: Int) {
        m_nombresCapas[nombre] = index
        switch nombre.trimmingCharacters(in: .whitespaces).lowercased() {
        case "obstaculos":          CAPA_OBSTACULOS = index
        case "terreno":             CAPA_TERRENO    = index
        case "unidades":            CAPA_UNIDADES_JUGADOR = index
        case "posicion invalidada": CAPA_POSICIONES_INVALIDADAS = index
        default: break
        }
    }

    fileprivate func agregarCapa(_ datos: [[Int16]]) {
        guard m_numeroMaximoDeCapas < NRO_MAXIMO_DE_CAPAS else { return }
        while m_mapa.count <= m_numeroMaximoDeCapas {
            m_mapa.append(Array(repeating: Array(repeating: 0, count: m_altoEnTiles),
                                count: m_anchoEnTiles))
        }
        m_mapa[m_numeroMaximoDeCapas] = datos
        m_numeroMaximoDeCapas += 1
    }

    fileprivate func agregarTileset(_ ts: Tileset) {
        guard m_tilesetMaximo < m_tilesets.count else { return }
        m_tilesets[m_tilesetMaximo] = ts
        m_tilesetMaximo += 1
    }

    fileprivate var anchoEnTiles:  Int { m_anchoEnTiles }
    fileprivate var altoEnTilesInt: Int { m_altoEnTiles }
}

// MARK: - Delegates XML privados

private class MapInfoDelegate: NSObject, XMLParserDelegate {
    var orientacion = ""; var ancho = 0; var alto = 0
    var tileAncho = 0; var tileAlto = 0
    var tileCamaraI = 0; var tileCamaraJ = 0
    private var enProperties = false

    func parser(_ parser: XMLParser, didStartElement name: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes a: [String: String]) {
        if name == "map" {
            orientacao = a["orientation"] ?? ""
            ancho     = Int(a["width"]      ?? "0") ?? 0
            alto      = Int(a["height"]     ?? "0") ?? 0
            tileAncho = Int(a["tilewidth"]  ?? "0") ?? 0
            tileAlto  = Int(a["tileheight"] ?? "0") ?? 0
        } else if name == "properties" {
            enProperties = true
        } else if enProperties && name == "property" {
            switch a["name"] ?? "" {
            case "CamaraTileInicialI": tileCamaraI = Int(a["value"] ?? "0") ?? 0
            case "CamaraTileInicialJ": tileCamaraJ = Int(a["value"] ?? "0") ?? 0
            default: break
            }
        }
    }
    func parser(_ parser: XMLParser, didEndElement name: String,
                namespaceURI: String?, qualifiedName: String?) {
        if name == "properties" { enProperties = false }
    }
    // Alias para evitar typo en Swift
    private var orientacao: String {
        get { orientacion } set { orientacion = newValue }
    }
}

private class TilesetRefDelegate: NSObject, XMLParserDelegate {
    private let base: String
    private let paths: [String?]
    private weak var mapa: Mapa?

    init(base: String, paths: [String?], mapa: Mapa) {
        self.base = base; self.paths = paths; self.mapa = mapa
    }

    func parser(_ parser: XMLParser, didStartElement name: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes a: [String: String]) {
        guard name == "tileset", let m = mapa else { return }
        let ts = Tileset()
        if let gid = a["firstgid"] { ts.primerGid = Int16(gid) ?? 0 }
        if let src = a["source"] {
            let candidate1 = (base as NSString).appendingPathComponent(src)
            let candidate2 = (Programa.PATH_ESCENARIOS as NSString).appendingPathComponent(src)
            let resolved = Utilidades.obtenerPath(candidate1)
                        ?? Utilidades.obtenerPath(candidate2)
                        ?? Utilidades.obtenerPath(src)
            if let p = resolved { ts.cargar(p) }
            else { Log.Instancia.error("Mapa: no se encuentra tileset \(src)") }
        }
        m.agregarTileset(ts)
    }
}

private class LayerDelegate: NSObject, XMLParserDelegate {
    private weak var mapa: Mapa?
    private var capaNombre = ""
    private var capaIndex  = 0
    private var inLayer    = false
    private var inData     = false
    private var encoding   = ""
    private var dataBuffer = ""

    init(mapa: Mapa) { self.mapa = mapa }

    func parser(_ parser: XMLParser, didStartElement name: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes a: [String: String]) {
        if name == "layer" {
            capaNombre = a["name"] ?? ""
            inLayer    = true
        } else if inLayer && name == "data" {
            encoding   = a["encoding"] ?? ""
            inData     = true
            dataBuffer = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inData { dataBuffer += string }
    }

    func parser(_ parser: XMLParser, didEndElement name: String,
                namespaceURI: String?, qualifiedName: String?) {
        guard let m = mapa else { return }
        if name == "data" && inData {
            inData = false
            if encoding == "base64" {
                let trimmed = dataBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
                if let decoded = Data(base64Encoded: trimmed) {
                    var datos = Array(repeating: Array(repeating: Int16(0), count: m.altoEnTilesInt),
                                      count: m.anchoEnTiles)
                    let bytes = [UInt8](decoded)
                    var idx = 0
                    for i in 0..<m.anchoEnTiles {
                        for j in 0..<m.altoEnTilesInt {
                            if idx < bytes.count {
                                datos[i][j] = Int16(bytes[idx])
                                idx += 4  // 32-bit LE tile ID; tomamos solo el primer byte
                            }
                        }
                    }
                    m.agregarNombreCapa(capaNombre, m.altoEnTilesInt == 0 ? 0 : capaIndex)
                    m.agregarCapa(datos)
                    capaIndex += 1
                }
            }
            dataBuffer = ""
        } else if name == "layer" {
            inLayer = false
        }
    }
}
