//
//  Map.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Mapa.cs — loads and renders an isometric map in TMX format (Tiled).
//  Supports multiple layers, tilesets, and mouse-driven camera scroll.
//

import Foundation

class Map {

    // MARK: - Constants
    private let MAX_LAYERS_COUNT = 8
    private let INFO_LAYER           = 8

    // MARK: - Layer indices (read from XML)
    private(set) var TERRAIN_LAYER:               Int = 0
    private var OBSTACLES_LAYER:                 Int = 0
    private var PLAYER_UNITS_LAYER:           Int = 0
    private var INVALIDATED_POSITIONS_LAYER:     Int = 0

    static let TILE_VISIBLE: Int = 1

    // MARK: - Datos del mapa
    /// `m_map[layer][i][j]` = tile ID (Int16).
    private var m_map: [[[Int16]]] = []           // [layer][col][row]
    private var m_layerNames: [String: Int] = [:]
    private var m_mapLoaded  = false
    private var m_maxLayers = 0

    private var m_heightInTiles:          Int = 0
    private var m_physicalHeightInTiles: Int = 0
    private var m_widthInTiles:         Int = 0
    private var m_physicalWidthInTiles: Int = 0

    private(set) var tileWidth:      Int = 0
    private(set) var tileHeight:       Int = 0
    private(set) var physicalTileWidth: Int = 0
    private(set) var physicalTileHeight:  Int = 0

    private var m_tilesets:      [Tileset?] = Array(repeating: nil, count: Res.TLS_COUNT)
    private var m_tilesetCount: Int = 0

    private static var m_tilesetDebug: Tileset?

    // MARK: - Mouse on tile
    private var m_tileMouse:      (x: Int, y: Int) = (0, 0)
    private var m_tileChicoMouse: (x: Int, y: Int) = (0, 0)

    // MARK: - Physical map (small tiles, ×2 resolution)
    private(set) var physicalTilesLayer:  [[Int16]] = []  // [col * 2][row * 2]
    var visibleTilesLayer: [[Int16]] = []

    // MARK: - Grey tile image (debug / semi-transparent selection)
    private var m_greyTileImage: Surface?

    // MARK: - Camera
    private let m_camera: Camera

    // MARK: - Public properties
    var height:      Int { m_heightInTiles }
    var width:     Int { m_widthInTiles }
    var physicalMapHeight:  Int { m_physicalHeightInTiles }
    var physicalMapWidth: Int { m_physicalWidthInTiles }

    var tileUnderMouse:      (x: Int, y: Int) { m_tileMouse }
    var smallTileUnderMouse:     (x: Int, y: Int) { m_tileChicoMouse }

    var unitsLayer: [[Int16]] {
        guard PLAYER_UNITS_LAYER < m_map.count else { return [] }
        return m_map[PLAYER_UNITS_LAYER]
    }
    var obstaclesLayer: [[Int16]] {
        guard OBSTACLES_LAYER < m_map.count else { return [] }
        return m_map[OBSTACLES_LAYER]
    }
    var buildingsLayer: [[Int16]] {
        guard INVALIDATED_POSITIONS_LAYER < m_map.count else { return [] }
        return m_map[INVALIDATED_POSITIONS_LAYER]
    }
    var terrainLayer: [[Int16]] {
        guard TERRAIN_LAYER < m_map.count else { return [] }
        return m_map[TERRAIN_LAYER]
    }
    var tilesets: [Tileset?] { m_tilesets }

    // MARK: - Initializer
    init(camera: Camera) {
        m_camera = camera
    }

    // MARK: - Loading

    @discardableResult
    func load(_ mapId: Int) -> Bool {
        guard mapId >= Res.TLS_COUNT, mapId < Res.TLS_COUNT + Res.MAP_COUNT else {
            Log.shared.error("Map ID \(mapId) inválido.")
            return false
        }
        let paths = ResourceManager.shared.scenarioPaths
        guard mapId < paths.count, let mapPath = paths[mapId] else {
            Log.shared.error("No hay path para el mapa \(mapId).")
            return false
        }

        m_tilesetCount = 0
        m_maxLayers = 0
        m_map = []
        m_layerNames = [:]

        guard readMapInfo(mapPath) else { return false }
        guard readTilesets(mapPath, paths: paths) else { return false }
        guard readLayers(mapPath) else { return false }

        loadLayerInfo(paths: paths)
        m_mapLoaded = true
        return true
    }

    // MARK: - Drawing

    /// Draws layer `layer` onto the given Video using the current camera.
    @discardableResult
    func drawLayer(_ g: Video, _ layer: Int) -> Bool {
        guard layer < m_maxLayers, layer >= 0 else { return false }
        guard m_mapLoaded else { return false }

        let oldClip = g.getClip()
        g.setClip(m_camera.startX, m_camera.startY, m_camera.width, m_camera.height)

        var toggle = true
        let p = calculateFirstTileToDraw(m_camera.X, m_camera.Y)
        var XX = p.x, YY = p.y

        var startPosX = m_camera.startX + (((XX - YY) * tileWidth) >> 1) + m_camera.X
        var startPosY = m_camera.startY + (((XX + YY) * tileHeight)  >> 1) + m_camera.Y

        while startPosY <= (m_camera.height + m_camera.startY) {
            var tileX = 0
            var i = XX, j = YY
            while (tileX * tileWidth + startPosX) <= (m_camera.startX + m_camera.width) && j >= 0 {
                if i < m_heightInTiles && i >= 0 && j < m_widthInTiles && j >= 0 {
                    let tileId = Int(m_map[layer][i][j])
                    if tileId != 0, let ts = getTileset(tileId) {
                        let localId = tileId - Int(ts.firstGid)
                        let rect = ts.getTileRect(localId)
                        g.draw(ts.image, rect.x, rect.y, rect.w, rect.h,
                                  tileX * tileWidth + startPosX, startPosY)
                    }
                }
                tileX += 1; i += 1; j -= 1
            }

            startPosY += tileHeight >> 1

            if toggle {
                XX += 1; startPosX += tileWidth >> 1; toggle = false
            } else {
                YY += 1; startPosX -= tileWidth >> 1; toggle = true
            }
        }

        g.setClip(oldClip.x, oldClip.y, oldClip.w, oldClip.h)
        return true
    }

    // MARK: - Tile Chico (fog-of-war)

    /// Draws a small tile (physical map) at the corresponding isometric position.
    /// If `semiTransparente` is true, draws the semi-transparent grey tile (fog-of-war).
    func drawSmallTile(_ g: Video, _ i: Int, _ j: Int, _ semiTransparente: Bool) {
        guard i >= 0, j >= 0, i < m_physicalHeightInTiles, j < m_physicalWidthInTiles else { return }

        let posX = m_camera.startX + (((i - j) * tileWidth / 2) >> 1) + m_camera.X + tileWidth / 4
        let posY = m_camera.startY + (((i + j) * tileHeight  / 2) >> 1) + m_camera.Y

        if semiTransparente {
            if m_greyTileImage == nil {
                m_greyTileImage = ResourceManager.shared.getImage(Res.IMG_TILE_GRIS)
            }
            g.draw(m_greyTileImage, posX, posY, 128, 0)
        }
    }

    // MARK: - Update (camera scroll)

    func update() {
        guard m_mapLoaded else { return }

        let mx = Int(Mouse.shared.X)
        let my = Int(Mouse.shared.Y)

        if mx < m_camera.border {
            if m_camera.X + m_camera.speed <= (m_widthInTiles * tileWidth) / 2 {
                let p = calculateFirstTileToDraw(m_camera.X, m_camera.Y)
                if p.x < -13 {
                    m_camera.Y -= m_camera.speed / 2
                } else {
                    let p2 = calculateFirstTileToDraw(m_camera.X, m_camera.Y - m_camera.height)
                    if p2.y > m_heightInTiles + 13 { m_camera.Y += m_camera.speed / 2 }
                }
                m_camera.X += m_camera.speed
            }
        }

        if my > m_camera.height - m_camera.border {
            if (m_camera.Y - m_camera.speed) >= (m_camera.height - m_heightInTiles * tileHeight) &&
               m_camera.Y - m_camera.speed <= 0 {
                let p = calculateFirstTileToDraw(m_camera.X, m_camera.Y - m_camera.height)
                if p.y > m_heightInTiles + 13 {
                    m_camera.Y -= m_camera.speed / 2
                    m_camera.X -= m_camera.speed
                } else {
                    let p2 = calculateFirstTileToDraw(m_camera.X - m_camera.width, m_camera.Y - m_camera.height)
                    if p2.x > m_widthInTiles + 13 {
                        m_camera.Y -= m_camera.speed / 2
                        m_camera.X += m_camera.speed
                    } else {
                        m_camera.Y -= m_camera.speed
                    }
                }
            }
        }

        if my < m_camera.border {
            if m_camera.Y + m_camera.speed <= 0 {
                let p = calculateFirstTileToDraw(m_camera.X, m_camera.Y)
                if p.x < -13 {
                    m_camera.X -= m_camera.speed
                    m_camera.Y += m_camera.speed / 2
                } else {
                    let p2 = calculateFirstTileToDraw(m_camera.X - m_camera.width, m_camera.Y)
                    if p2.y < -13 {
                        m_camera.X += m_camera.speed
                        m_camera.Y += m_camera.speed / 2
                    } else {
                        m_camera.Y += m_camera.speed
                    }
                }
            }
        }

        if mx > m_camera.width - m_camera.border {
            let p = calculateFirstTileToDraw(m_camera.X - m_camera.width, m_camera.Y)
            if (m_camera.X - m_camera.width - m_camera.speed + tileWidth)
                >= -(m_widthInTiles * tileWidth) / 2 ||
               (m_camera.X - m_camera.speed) > 0 {
                if p.y < -13 {
                    m_camera.Y -= m_camera.speed / 2
                } else {
                    let p2 = calculateFirstTileToDraw(m_camera.X - m_camera.width, m_camera.Y - m_camera.height)
                    if p2.x > m_heightInTiles + 13 { m_camera.Y += m_camera.speed / 2 }
                }
                m_camera.X -= m_camera.speed
            }
        }

        updateMouseCoords()
    }

    // MARK: - Public queries

    func getTileset(_ tileId: Int) -> Tileset? {
        var result: Tileset? = nil
        for i in 0..<m_tilesetCount {
            if let ts = m_tilesets[i], tileId >= Int(ts.firstGid) {
                result = ts
            }
        }
        return result
    }

    func isWalkable(_ x: Int, _ y: Int) -> Bool {
        guard x >= 0, y >= 0,
              x < m_widthInTiles * 2, y < m_heightInTiles * 2,
              x < physicalTilesLayer.count,
              y < physicalTilesLayer[x].count else { return false }
        let id = Int(physicalTilesLayer[x][y])
        return id == Res.TLS_PASTO || id == Res.TLS_TIERRA
    }

    /// Walks from (x1,y1) toward (x2,y2) along the Bresenham-style parametric line and
    /// returns the first walkable tile it encounters (port of C# ObtenerPosicionEnLineaDeVision).
    /// Returns (-1,-1) if no walkable tile is found.
    func getLineOfSightPosition(_ x1: Int, _ x2: Int, _ y1: Int, _ y2: Int) -> (x: Int, y: Int) {
        var col = Float(x1)
        var row    = Float(y1)

        let rowSlope    = getRowSlope(x1, x2, y1, y2)
        let colSlope = getColumnSlope(x1, x2, y1, y2)

        if abs(rowSlope) == 1.0 {
            while Int(row.rounded(.down)) != y2 {
                let ci = Int(col.rounded(.down))
                let fi = Int(row.rounded(.down))
                if isWalkable(ci, fi) { return (ci, fi) }
                row    += rowSlope
                col += colSlope
            }
        } else {
            while Int(col.rounded(.down)) != x2 {
                let ci = Int(col.rounded(.down))
                let fi = Int(row.rounded(.down))
                if isWalkable(ci, fi) { return (ci, fi) }
                row    += rowSlope
                col += colSlope
            }
        }
        return (-1, -1)
    }

    private func getRowSlope(_ x1: Int, _ x2: Int, _ y1: Int, _ y2: Int) -> Float {
        if abs(y2 - y1) > abs(x2 - x1) {
            return y2 > y1 ? 1 : -1
        } else {
            let d = Float(abs(y2 - y1)) / Float(abs(x2 - x1))
            return d * (y2 > y1 ? 1 : -1)
        }
    }

    private func getColumnSlope(_ x1: Int, _ x2: Int, _ y1: Int, _ y2: Int) -> Float {
        if abs(x2 - x1) > abs(y2 - y1) {
            return x2 > x1 ? 1 : -1
        } else {
            let d = Float(abs(x2 - x1)) / Float(abs(y2 - y1))
            return d * (x2 > x1 ? 1 : -1)
        }
    }

    func invalidateTile(_ x: Int, _ y: Int) {
        guard x >= 0, y >= 0,
              x + 1 < m_widthInTiles * 2,
              y + 1 < m_heightInTiles * 2 else { return }
        let v = Int16(Res.TLS_ARBOLES)
        physicalTilesLayer[x][y]         = v
        physicalTilesLayer[x + 1][y]     = v
        physicalTilesLayer[x + 1][y + 1] = v
        physicalTilesLayer[x][y + 1]     = v
    }

    // MARK: - Private

    private func calculateFirstTileToDraw(_ x: Int, _ y: Int) -> (x: Int, y: Int) {
        let a = tileHeight > 0 ? -y / tileHeight : 0
        var b = tileWidth > 0 ? x / tileWidth : 0
        if x > 0 { b += 1 }
        return (a - b - 2, a + b - 1)
    }

    private func updateMouseCoords() {
        guard m_mapLoaded else { return }
        let p = tilePositionFromXY(Int(Mouse.shared.X), Int(Mouse.shared.Y))
        m_tileMouse = p
    }

    private func tilePositionFromXY(_ x: Int, _ y: Int) -> (x: Int, y: Int) {
        guard tileHeight > 0, tileWidth > 0 else { return (0, 0) }
        // Logical tile coords (for m_tileMouse — buildings, obstacles)
        let a = (y - m_camera.Y - m_camera.startY) / tileHeight
        let b: Int
        if x - m_camera.X > 0 {
            b = (x - m_camera.X - m_camera.startX) / tileWidth
        } else {
            b = (x - m_camera.X - m_camera.startX - tileWidth) / tileWidth
        }
        // Physical tile coords (2× resolution — for m_tileChicoMouse, pathfinding, movement)
        let aF = (y - m_camera.Y - m_camera.startY) / physicalTileHeight
        let bF: Int
        if x - m_camera.X > 0 {
            bF = (x - m_camera.X - m_camera.startX) / physicalTileWidth
        } else {
            bF = (x - m_camera.X - m_camera.startX - physicalTileWidth) / physicalTileWidth
        }
        m_tileChicoMouse = (aF + bF, aF - bF)
        return (a + b, a - b)
    }

    // MARK: - Internal TMX loading

    private func readMapInfo(_ path: String) -> Bool {
        guard let parser = XMLParser(contentsOf: URL(fileURLWithPath: path)) else { return false }
        let d = MapInfoDelegate()
        parser.delegate = d
        guard parser.parse() else { return false }
        guard d.orientation == "isometric" else {
            Log.shared.error("Map: orientación no isométrica."); return false
        }
        m_widthInTiles = d.width;  m_physicalWidthInTiles = d.width * 2
        m_heightInTiles  = d.height;   m_physicalHeightInTiles  = d.height  * 2
        tileWidth = d.tileWidth;   physicalTileWidth = d.tileWidth / 2
        tileHeight  = d.tileHeight;    physicalTileHeight  = d.tileHeight  / 2
        m_camera.X = ((d.tileCamaraJ - d.tileCamaraI) * tileWidth) >> 1
        m_camera.Y = -((d.tileCamaraJ + d.tileCamaraI) * tileHeight) >> 1
        return true
    }

    private func readTilesets(_ mapPath: String, paths: [String?]) -> Bool {
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
            ts.firstGid = entry.gid
            ts.load(entry.path)
            addTileset(ts)
        }
        return true
    }

    private func readLayers(_ path: String) -> Bool {
        guard let parser = XMLParser(contentsOf: URL(fileURLWithPath: path)) else { return false }
        let d = LayerDelegate(map: self)
        parser.delegate = d
        let ok = parser.parse()
        withExtendedLifetime(d) {}
        return ok
    }

    private func loadLayerInfo(paths: [String?]) {
        if Map.m_tilesetDebug == nil {
            let ts = Tileset()
            if let p = paths[Res.TLS_DEBUG] { ts.load(p) }
            Map.m_tilesetDebug = ts
        }

        // Expand the map to the INFO layer (INFO_LAYER = 8)
        while m_map.count <= INFO_LAYER {
            m_map.append(Array(repeating: Array(repeating: 0, count: m_heightInTiles),
                                count: m_widthInTiles))
        }

        // Initialize the physical map and visibility map (double resolution)
        physicalTilesLayer  = Array(repeating: Array(repeating: 0, count: m_heightInTiles * 2),
                                  count: m_widthInTiles * 2)
        visibleTilesLayer = Array(repeating: Array(repeating: 0, count: m_heightInTiles * 2),
                                  count: m_widthInTiles * 2)

        for layer in 0..<m_maxLayers {
            for i in 0..<m_widthInTiles {
                for j in 0..<m_heightInTiles {
                    if let ts = getTileset(Int(m_map[layer][i][j])),
                       ts.id != Int16(Res.TLS_UNIDADES) {
                        let tsId = ts.id
                        m_map[INFO_LAYER][i][j] = tsId
                        let ci = i * 2, cj = j * 2
                        if ci + 1 < physicalTilesLayer.count && cj + 1 < physicalTilesLayer[ci].count {
                            physicalTilesLayer[ci][cj]     = tsId
                            physicalTilesLayer[ci][cj + 1] = tsId
                            physicalTilesLayer[ci + 1][cj] = tsId
                            physicalTilesLayer[ci + 1][cj + 1] = tsId
                        }
                    }
                }
            }
        }
        _ = PathFinder.instance.loadMap(self)
    }

    // MARK: - Helpers called from delegates

    fileprivate func addLayerName(_ name: String, _ index: Int) {
        m_layerNames[name] = index
        switch name.trimmingCharacters(in: .whitespaces).lowercased() {
        case "obstaculos":          OBSTACLES_LAYER = index
        case "terreno":             TERRAIN_LAYER    = index
        case "unidades":            PLAYER_UNITS_LAYER = index
        case "posicion invalidada": INVALIDATED_POSITIONS_LAYER = index
        default: break
        }
    }

    fileprivate func addLayer(_ layerData: [[Int16]]) {
        guard m_maxLayers < MAX_LAYERS_COUNT else { return }
        while m_map.count <= m_maxLayers {
            m_map.append(Array(repeating: Array(repeating: 0, count: m_heightInTiles),
                                count: m_widthInTiles))
        }
        m_map[m_maxLayers] = layerData
        m_maxLayers += 1
    }

    fileprivate func addTileset(_ ts: Tileset) {
        guard m_tilesetCount < m_tilesets.count else { return }
        m_tilesets[m_tilesetCount] = ts
        m_tilesetCount += 1
    }

    fileprivate var widthInTiles:  Int { m_widthInTiles }
    fileprivate var heightInTiles: Int { m_heightInTiles }
}

// MARK: - Private XML delegates

private class MapInfoDelegate: NSObject, XMLParserDelegate {
    var orientation = ""; var width = 0; var height = 0
    var tileWidth = 0; var tileHeight = 0
    var tileCamaraI = 0; var tileCamaraJ = 0
    private var enProperties = false

    func parser(_ parser: XMLParser, didStartElement name: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes a: [String: String]) {
        if name == "map" {
            orientacao = a["orientation"] ?? ""
            width     = Int(a["width"]      ?? "0") ?? 0
            height      = Int(a["height"]     ?? "0") ?? 0
            tileWidth = Int(a["tilewidth"]  ?? "0") ?? 0
            tileHeight  = Int(a["tileheight"] ?? "0") ?? 0
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
        get { orientation } set { orientation = newValue }
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
        let candidate2 = (Program.SCENARIOS_PATH as NSString).appendingPathComponent(src)
        if let p = Utils.getPath(candidate1)
                ?? Utils.getPath(candidate2)
                ?? Utils.getPath(src) {
            collected.append((gid: gid, path: p))
        } else {
            Log.shared.error("Map: no se encuentra tileset \(src)")
        }
    }
}

private class LayerDelegate: NSObject, XMLParserDelegate {
    private weak var map: Map?
    private var layerName = ""
    private var layerIndex  = 0
    private var inLayer    = false
    private var inData     = false
    private var encoding   = ""
    private var dataBuffer = ""

    init(map: Map) { self.map = map }

    func parser(_ parser: XMLParser, didStartElement name: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes a: [String: String]) {
        if name == "layer" {
            layerName = a["name"] ?? ""
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
        guard let m = map else { return }
        if name == "data" && inData {
            inData = false
            if encoding == "base64" {
                let trimmed = dataBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
                if let decoded = Data(base64Encoded: trimmed, options: .ignoreUnknownCharacters) {
                    var tiles = Array(repeating: Array(repeating: Int16(0), count: m.heightInTiles),
                                      count: m.widthInTiles)
                    let bytes = [UInt8](decoded)
                    var idx = 0
                    // TMX stores tiles row by row (row-major): first all columns
                    // of row 0, then those of row 1, etc.
                    for j in 0..<m.heightInTiles {
                        for i in 0..<m.widthInTiles {
                            if idx + 3 < bytes.count {
                                // 32-bit little-endian tile ID
                                let id = UInt32(bytes[idx])
                                    | UInt32(bytes[idx+1]) << 8
                                    | UInt32(bytes[idx+2]) << 16
                                    | UInt32(bytes[idx+3]) << 24
                                tiles[i][j] = Int16(id & 0x1FFF) // flip bit mask (bits 29-31)
                            }
                            idx += 4
                        }
                    }
                    m.addLayerName(layerName, m.heightInTiles == 0 ? 0 : layerIndex)
                    m.addLayer(tiles)
                    layerIndex += 1
                }
            }
            dataBuffer = ""
        } else if name == "layer" {
            inLayer = false
        }
    }
}
