//
//  Mapa.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Mapa.cs — loads and renders an isometric map in TMX format (Tiled).
//  Supports multiple layers, tilesets, and mouse-driven camera scroll.
//

import Foundation

class Mapa {

    // MARK: - Constants
    private let NRO_MAXIMO_DE_CAPAS = 8
    private let CAPA_INFO           = 8

    // MARK: - Layer indices (read from XML)
    private(set) var CAPA_TERRENO:               Int = 0
    private var CAPA_OBSTACULOS:                 Int = 0
    private var CAPA_UNIDADES_JUGADOR:           Int = 0
    private var CAPA_POSICIONES_INVALIDADAS:     Int = 0

    static let TILE_VISIBLE: Int = 1

    // MARK: - Datos del mapa
    /// `m_mapa[capa][i][j]` = tile ID (Int16).
    private var m_mapa: [[[Int16]]] = []           // [layer][col][row]
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

    // MARK: - Mouse on tile
    private var m_tileMouse:      (x: Int, y: Int) = (0, 0)
    private var m_tileChicoMouse: (x: Int, y: Int) = (0, 0)

    // MARK: - Physical map (small tiles, ×2 resolution)
    private(set) var capaTilesFisicos:  [[Int16]] = []  // [col * 2][row * 2]
    var capaTilesVisibles: [[Int16]] = []

    // MARK: - Grey tile image (debug / semi-transparent selection)
    private var m_imagenTileGris: Superficie?

    // MARK: - Camera
    private let m_camara: Camara

    // MARK: - Public properties
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

    // MARK: - Initializer
    init(camara: Camara) {
        m_camara = camara
    }

    // MARK: - Loading

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

    // MARK: - Drawing

    /// Draws layer `layer` onto the given Video using the current camera.
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

    /// Draws a small tile (physical map) at the corresponding isometric position.
    /// If `semiTransparente` is true, draws the semi-transparent grey tile (fog-of-war).
    func dibujarTileChico(_ g: Video, _ i: Int, _ j: Int, _ semiTransparente: Bool) {
        guard i >= 0, j >= 0, i < m_altoEnTilesMapaFisico, j < m_anchoEnTilesMapaFisico else { return }

        let posX = m_camara.inicioX + (((i - j) * tileAncho / 2) >> 1) + m_camara.X + tileAncho / 4
        let posY = m_camara.inicioY + (((i + j) * tileAlto  / 2) >> 1) + m_camara.Y

        if semiTransparente {
            if m_imagenTileGris == nil {
                m_imagenTileGris = AdministradorDeRecursos.Instancia.obtenerImagen(Res.IMG_TILE_GRIS)
            }
            g.dibujar(m_imagenTileGris, posX, posY, 128, 0)
        }
    }

    // MARK: - Update (camera scroll)

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

    // MARK: - Public queries

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

    /// Walks from (x1,y1) toward (x2,y2) along the Bresenham-style parametric line and
    /// returns the first walkable tile it encounters (port of C# ObtenerPosicionEnLineaDeVision).
    /// Returns (-1,-1) if no walkable tile is found.
    func obtenerPosicionEnLineaDeVision(_ x1: Int, _ x2: Int, _ y1: Int, _ y2: Int) -> (x: Int, y: Int) {
        var columna = Float(x1)
        var fila    = Float(y1)

        let decliveFila    = obtenerDecliveFila(x1, x2, y1, y2)
        let decliveColumna = obtenerDecliveColumna(x1, x2, y1, y2)

        if abs(decliveFila) == 1.0 {
            while Int(fila.rounded(.down)) != y2 {
                let ci = Int(columna.rounded(.down))
                let fi = Int(fila.rounded(.down))
                if esPosicionCaminable(ci, fi) { return (ci, fi) }
                fila    += decliveFila
                columna += decliveColumna
            }
        } else {
            while Int(columna.rounded(.down)) != x2 {
                let ci = Int(columna.rounded(.down))
                let fi = Int(fila.rounded(.down))
                if esPosicionCaminable(ci, fi) { return (ci, fi) }
                fila    += decliveFila
                columna += decliveColumna
            }
        }
        return (-1, -1)
    }

    private func obtenerDecliveFila(_ x1: Int, _ x2: Int, _ y1: Int, _ y2: Int) -> Float {
        if abs(y2 - y1) > abs(x2 - x1) {
            return y2 > y1 ? 1 : -1
        } else {
            let d = Float(abs(y2 - y1)) / Float(abs(x2 - x1))
            return d * (y2 > y1 ? 1 : -1)
        }
    }

    private func obtenerDecliveColumna(_ x1: Int, _ x2: Int, _ y1: Int, _ y2: Int) -> Float {
        if abs(x2 - x1) > abs(y2 - y1) {
            return x2 > x1 ? 1 : -1
        } else {
            let d = Float(abs(x2 - x1)) / Float(abs(y2 - y1))
            return d * (x2 > x1 ? 1 : -1)
        }
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

    // MARK: - Private

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
        // Logical tile coords (for m_tileMouse — buildings, obstacles)
        let a = (y - m_camara.Y - m_camara.inicioY) / tileAlto
        let b: Int
        if x - m_camara.X > 0 {
            b = (x - m_camara.X - m_camara.inicioX) / tileAncho
        } else {
            b = (x - m_camara.X - m_camara.inicioX - tileAncho) / tileAncho
        }
        // Physical tile coords (2× resolution — for m_tileChicoMouse, pathfinding, movement)
        let aF = (y - m_camara.Y - m_camara.inicioY) / tileFisicoAlto
        let bF: Int
        if x - m_camara.X > 0 {
            bF = (x - m_camara.X - m_camara.inicioX) / tileFisicoAncho
        } else {
            bF = (x - m_camara.X - m_camara.inicioX - tileFisicoAncho) / tileFisicoAncho
        }
        m_tileChicoMouse = (aF + bF, aF - bF)
        return (a + b, a - b)
    }

    // MARK: - Internal TMX loading

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
        let d = TilesetRefDelegate(base: base)
        parser.delegate = d
        let ok = parser.parse()
        withExtendedLifetime(d) {}
        guard ok else { return false }
        // Load each TSX *after* the TMX parser has fully finished — avoids reentrant XMLParser.
        for entry in d.collected {
            let ts = Tileset()
            ts.primerGid = entry.gid
            ts.cargar(entry.path)
            agregarTileset(ts)
        }
        return true
    }

    private func leerCapas(_ path: String) -> Bool {
        guard let parser = XMLParser(contentsOf: URL(fileURLWithPath: path)) else { return false }
        let d = LayerDelegate(mapa: self)
        parser.delegate = d
        let ok = parser.parse()
        withExtendedLifetime(d) {}
        return ok
    }

    private func cargarCapaInfo(paths: [String?]) {
        if Mapa.m_tilesetDebug == nil {
            let ts = Tileset()
            if let p = paths[Res.TLS_DEBUG] { ts.cargar(p) }
            Mapa.m_tilesetDebug = ts
        }

        // Expand the map to the INFO layer (CAPA_INFO = 8)
        while m_mapa.count <= CAPA_INFO {
            m_mapa.append(Array(repeating: Array(repeating: 0, count: m_altoEnTiles),
                                count: m_anchoEnTiles))
        }

        // Initialize the physical map and visibility map (double resolution)
        capaTilesFisicos  = Array(repeating: Array(repeating: 0, count: m_altoEnTiles * 2),
                                  count: m_anchoEnTiles * 2)
        capaTilesVisibles = Array(repeating: Array(repeating: 0, count: m_altoEnTiles * 2),
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
        _ = PathFinder.Instancia.cargarMapa(self)
    }

    // MARK: - Helpers called from delegates

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

// MARK: - Private XML delegates

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
    /// Collected during parsing; tilesets are loaded after parse() returns to avoid reentrance.
    var collected: [(gid: Int16, path: String)] = []

    init(base: String) {
        self.base = base
    }

    func parser(_ parser: XMLParser, didStartElement name: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes a: [String: String]) {
        guard name == "tileset", let src = a["source"] else { return }
        let gid = Int16(a["firstgid"] ?? "0") ?? 0
        let candidate1 = (base as NSString).appendingPathComponent(src)
        let candidate2 = (Programa.PATH_ESCENARIOS as NSString).appendingPathComponent(src)
        if let p = Utilidades.obtenerPath(candidate1)
                ?? Utilidades.obtenerPath(candidate2)
                ?? Utilidades.obtenerPath(src) {
            collected.append((gid: gid, path: p))
        } else {
            Log.Instancia.error("Mapa: no se encuentra tileset \(src)")
        }
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
                if let decoded = Data(base64Encoded: trimmed, options: .ignoreUnknownCharacters) {
                    var datos = Array(repeating: Array(repeating: Int16(0), count: m.altoEnTilesInt),
                                      count: m.anchoEnTiles)
                    let bytes = [UInt8](decoded)
                    var idx = 0
                    // TMX stores tiles row by row (row-major): first all columns
                    // of row 0, then those of row 1, etc.
                    for j in 0..<m.altoEnTilesInt {
                        for i in 0..<m.anchoEnTiles {
                            if idx + 3 < bytes.count {
                                // 32-bit little-endian tile ID
                                let id = UInt32(bytes[idx])
                                    | UInt32(bytes[idx+1]) << 8
                                    | UInt32(bytes[idx+2]) << 16
                                    | UInt32(bytes[idx+3]) << 24
                                datos[i][j] = Int16(id & 0x1FFF) // flip bit mask (bits 29-31)
                            }
                            idx += 4
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
