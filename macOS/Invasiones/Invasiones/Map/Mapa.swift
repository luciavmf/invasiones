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
    enum Constants {
        static let maxLayersCount = 8
        static let infoLayer = 8
        static let visibleTile: Int = 1
    }

    // MARK: - Layer indices (read from XML)
    struct LayerIndices {
        var terrain: Int = 0
        var obstacles: Int = 0
        var playerUnits: Int = 0
        var invalidatedPositions: Int = 0
    }

    private(set) var layers = LayerIndices()

    // MARK: - Datos del mapa
    private var mapData: [[[Int]]] = []           // [layer][col][row]
    private var layerNames: [String: Int] = [:]
    private var mapLoaded = false
    private var maxLayers = 0

    private(set) var height: Int = 0
    private var physicalHeight: Int = 0
    private(set) var width: Int = 0
    private var physicalWidth: Int = 0

    private(set) var tileWidth: Int = 0
    private(set) var tileHeight: Int = 0
    private(set) var physicalTileWidth: Int = 0
    private(set) var physicalTileHeight: Int = 0

    private(set) var tilesets: [Tileset?] = Array(repeating: nil, count: Res.TLS_COUNT)
    private var tilesetCount: Int = 0

    private static var tilesetDebug: Tileset?

    // MARK: - Mouse on tile
    private(set) var tileUnderMouse: (x: Int, y: Int) = (0, 0)
    private(set) var smallTileUnderMouse: (x: Int, y: Int) = (0, 0)

    // MARK: - Physical map (small tiles, ×2 resolution)
    private(set) var physicalTilesLayer: [[Int]] = []  // [col * 2][row * 2]
    var visibleTilesLayer: [[Int]] = []

    // MARK: - Grey tile image (debug / semi-transparent selection)
    private var greyTileImage: Surface?

    // MARK: - Camera
    private let camera: Camera

    // MARK: - Computed helpers
    var physicalMapHeight: Int { physicalHeight }
    var physicalMapWidth: Int { physicalWidth }

    var unitsLayer: [[Int]] {
        guard layers.playerUnits < mapData.count else { return [] }
        return mapData[layers.playerUnits]
    }
    var obstaclesLayer: [[Int]] {
        guard layers.obstacles < mapData.count else { return [] }
        return mapData[layers.obstacles]
    }
    var buildingsLayer: [[Int]] {
        guard layers.invalidatedPositions < mapData.count else { return [] }
        return mapData[layers.invalidatedPositions]
    }
    var terrainLayer: [[Int]] {
        guard layers.terrain < mapData.count else { return [] }
        return mapData[layers.terrain]
    }

    // MARK: - Initializer
    init(camera: Camera) {
        self.camera = camera
    }

    // MARK: - Loading

    func load(_ mapId: Int) throws {
        guard mapId >= Res.TLS_COUNT, mapId < Res.TLS_COUNT + Res.MAP_COUNT else {
            throw GameError.invalidResource("Map ID \(mapId) inválido.")
        }
        let paths = ResourceManager.shared.scenarioPaths
        guard mapId < paths.count, let mapPath = paths[mapId] else {
            throw GameError.fileNotFound("No hay path para el mapa \(mapId).")
        }

        tilesetCount = 0
        maxLayers = 0
        mapData = []
        layerNames = [:]

        try readMapInfo(mapPath)
        try readTilesets(mapPath, paths: paths)
        try readLayers(mapPath)

        loadLayerInfo(paths: paths)
        mapLoaded = true
    }

    // MARK: - Drawing

    /// Draws layer `layer` onto the given Video using the current camera.
    @discardableResult
    func drawLayer(g: Video, layer: Int) -> Bool {
        guard layer < maxLayers, layer >= 0 else { return false }
        guard mapLoaded else { return false }

        let oldClip = g.getClip()
        g.setClip(x: camera.startX, y: camera.startY, w: camera.width, h: camera.height)

        var toggle = true
        let p = calculateFirstTileToDraw(x: camera.X, y: camera.Y)
        var XX = p.x, YY = p.y

        var startPosX = camera.startX + (((XX - YY) * tileWidth) >> 1) + camera.X
        var startPosY = camera.startY + (((XX + YY) * tileHeight)  >> 1) + camera.Y

        while startPosY <= (camera.height + camera.startY) {
            var tileX = 0
            var i = XX, j = YY
            while (tileX * tileWidth + startPosX) <= (camera.startX + camera.width) && j >= 0 {
                if i < height && i >= 0 && j < width && j >= 0 {
                    let tileId = mapData[layer][i][j]
                    if tileId != 0, let ts = getTileset(tileId) {
                        let localId = tileId - ts.firstGid
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

        g.setClip(x: oldClip.x, y: oldClip.y, w: oldClip.w, h: oldClip.h)
        return true
    }

    // MARK: - Tile Chico (fog-of-war)

    /// Draws a small tile (physical map) at the corresponding isometric position.
    /// If `semiTransparent` is true, draws the semi-transparent grey tile (fog-of-war).
    func drawSmallTile(g: Video, i: Int, j: Int, semiTransparent: Bool) {
        guard i >= 0, j >= 0, i < physicalHeight, j < physicalWidth else { return }

        let posX = camera.startX + (((i - j) * tileWidth / 2) >> 1) + camera.X + tileWidth / 4
        let posY = camera.startY + (((i + j) * tileHeight  / 2) >> 1) + camera.Y

        if semiTransparent {
            if greyTileImage == nil {
                greyTileImage = ResourceManager.shared.getImage(Res.IMG_TILE_GRIS)
            }
            g.draw(greyTileImage, posX, posY, 128, 0)
        }
    }

    // MARK: - Update (camera scroll)

    func update() {
        guard mapLoaded else { return }

        let mx = Int(Mouse.shared.X)
        let my = Int(Mouse.shared.Y)

        if mx < camera.border {
            if camera.X + camera.speed <= (width * tileWidth) / 2 {
                let p = calculateFirstTileToDraw(x: camera.X, y: camera.Y)
                if p.x < -13 {
                    camera.Y -= camera.speed / 2
                } else {
                    let p2 = calculateFirstTileToDraw(x: camera.X, y: camera.Y - camera.height)
                    if p2.y > height + 13 { camera.Y += camera.speed / 2 }
                }
                camera.X += camera.speed
            }
        }

        if my > camera.height - camera.border {
            if (camera.Y - camera.speed) >= (camera.height - height * tileHeight) &&
               camera.Y - camera.speed <= 0 {
                let p = calculateFirstTileToDraw(x: camera.X, y: camera.Y - camera.height)
                if p.y > height + 13 {
                    camera.Y -= camera.speed / 2
                    camera.X -= camera.speed
                } else {
                    let p2 = calculateFirstTileToDraw(x: camera.X - camera.width, y: camera.Y - camera.height)
                    if p2.x > width + 13 {
                        camera.Y -= camera.speed / 2
                        camera.X += camera.speed
                    } else {
                        camera.Y -= camera.speed
                    }
                }
            }
        }

        if my < camera.border {
            if camera.Y + camera.speed <= 0 {
                let p = calculateFirstTileToDraw(x: camera.X, y: camera.Y)
                if p.x < -13 {
                    camera.X -= camera.speed
                    camera.Y += camera.speed / 2
                } else {
                    let p2 = calculateFirstTileToDraw(x: camera.X - camera.width, y: camera.Y)
                    if p2.y < -13 {
                        camera.X += camera.speed
                        camera.Y += camera.speed / 2
                    } else {
                        camera.Y += camera.speed
                    }
                }
            }
        }

        if mx > camera.width - camera.border {
            let p = calculateFirstTileToDraw(x: camera.X - camera.width, y: camera.Y)
            if (camera.X - camera.width - camera.speed + tileWidth)
                >= -(width * tileWidth) / 2 ||
               (camera.X - camera.speed) > 0 {
                if p.y < -13 {
                    camera.Y -= camera.speed / 2
                } else {
                    let p2 = calculateFirstTileToDraw(x: camera.X - camera.width, y: camera.Y - camera.height)
                    if p2.x > height + 13 { camera.Y += camera.speed / 2 }
                }
                camera.X -= camera.speed
            }
        }

        updateMouseCoords()
    }

    // MARK: - Public queries

    func getTileset(_ tileId: Int) -> Tileset? {
        var result: Tileset? = nil
        for i in 0..<tilesetCount {
            if let ts = tilesets[i], tileId >= ts.firstGid {
                result = ts
            }
        }
        return result
    }

    func isWalkable(x: Int, y: Int) -> Bool {
        guard x >= 0, y >= 0,
              x < width * 2, y < height * 2,
              x < physicalTilesLayer.count,
              y < physicalTilesLayer[x].count else { return false }
        let id = physicalTilesLayer[x][y]
        return id == Res.TLS_PASTO || id == Res.TLS_TIERRA
    }

    /// Walks from (x1,y1) toward (x2,y2) along the Bresenham-style parametric line and
    /// returns the first walkable tile it encounters (port of C# ObtenerPosicionEnLineaDeVision).
    /// Returns (-1,-1) if no walkable tile is found.
    func getLineOfSightPosition(x1: Int, x2: Int, y1: Int, y2: Int) -> (x: Int, y: Int) {
        var col = Float(x1)
        var row = Float(y1)

        let rowSlope = getRowSlope(x1: x1, x2: x2, y1: y1, y2: y2)
        let colSlope = getColumnSlope(x1: x1, x2: x2, y1: y1, y2: y2)

        if abs(rowSlope) == 1.0 {
            while Int(row.rounded(.down)) != y2 {
                let ci = Int(col.rounded(.down))
                let fi = Int(row.rounded(.down))
                if isWalkable(x: ci, y: fi) { return (ci, fi) }
                row += rowSlope
                col += colSlope
            }
        } else {
            while Int(col.rounded(.down)) != x2 {
                let ci = Int(col.rounded(.down))
                let fi = Int(row.rounded(.down))
                if isWalkable(x: ci, y: fi) { return (ci, fi) }
                row += rowSlope
                col += colSlope
            }
        }
        return (-1, -1)
    }

    private func getRowSlope(x1: Int, x2: Int, y1: Int, y2: Int) -> Float {
        if abs(y2 - y1) > abs(x2 - x1) {
            return y2 > y1 ? 1 : -1
        } else {
            let d = Float(abs(y2 - y1)) / Float(abs(x2 - x1))
            return d * (y2 > y1 ? 1 : -1)
        }
    }

    private func getColumnSlope(x1: Int, x2: Int, y1: Int, y2: Int) -> Float {
        if abs(x2 - x1) > abs(y2 - y1) {
            return x2 > x1 ? 1 : -1
        } else {
            let d = Float(abs(x2 - x1)) / Float(abs(y2 - y1))
            return d * (x2 > x1 ? 1 : -1)
        }
    }

    func invalidateTile(x: Int, y: Int) {
        guard x >= 0, y >= 0,
              x + 1 < width * 2,
              y + 1 < height * 2 else { return }
        let v = Res.TLS_ARBOLES
        physicalTilesLayer[x][y]         = v
        physicalTilesLayer[x + 1][y]     = v
        physicalTilesLayer[x + 1][y + 1] = v
        physicalTilesLayer[x][y + 1]     = v
    }

    // MARK: - Private

    private func calculateFirstTileToDraw(x: Int, y: Int) -> (x: Int, y: Int) {
        let a = tileHeight > 0 ? -y / tileHeight : 0
        var b = tileWidth > 0 ? x / tileWidth : 0
        if x > 0 { b += 1 }
        return (a - b - 2, a + b - 1)
    }

    private func updateMouseCoords() {
        guard mapLoaded else { return }
        let p = tilePositionFromXY(x: Int(Mouse.shared.X), y: Int(Mouse.shared.Y))
        tileUnderMouse = p
    }

    private func tilePositionFromXY(x: Int, y: Int) -> (x: Int, y: Int) {
        guard tileHeight > 0, tileWidth > 0 else { return (0, 0) }
        // Logical tile coords (for tileUnderMouse — buildings, obstacles)
        let a = (y - camera.Y - camera.startY) / tileHeight
        let b: Int
        if x - camera.X > 0 {
            b = (x - camera.X - camera.startX) / tileWidth
        } else {
            b = (x - camera.X - camera.startX - tileWidth) / tileWidth
        }
        // Physical tile coords (2× resolution — for smallTileUnderMouse, pathfinding, movement)
        let aF = (y - camera.Y - camera.startY) / physicalTileHeight
        let bF: Int
        if x - camera.X > 0 {
            bF = (x - camera.X - camera.startX) / physicalTileWidth
        } else {
            bF = (x - camera.X - camera.startX - physicalTileWidth) / physicalTileWidth
        }
        smallTileUnderMouse = (aF + bF, aF - bF)
        return (a + b, a - b)
    }

    // MARK: - Internal TMX loading

    private func readMapInfo(_ path: String) throws {
        guard let parser = XMLParser(contentsOf: URL(fileURLWithPath: path)) else {
            throw GameError.fileNotFound("Map: no se puede abrir \(path)")
        }
        let d = MapInfoDelegate()
        parser.delegate = d
        guard parser.parse() else {
            throw GameError.parsingFailed("Map: error al parsear \(path)")
        }
        guard d.orientation == "isometric" else {
            throw GameError.invalidResource("Map: orientación no isométrica.")
        }
        width = d.width; physicalWidth = d.width * 2
        height = d.height; physicalHeight = d.height * 2
        tileWidth = d.tileWidth; physicalTileWidth = d.tileWidth / 2
        tileHeight = d.tileHeight; physicalTileHeight = d.tileHeight / 2
        camera.X = ((d.tileCamaraJ - d.tileCamaraI) * tileWidth) >> 1
        camera.Y = -((d.tileCamaraJ + d.tileCamaraI) * tileHeight) >> 1
    }

    private func readTilesets(_ mapPath: String, paths: [String?]) throws {
        guard let parser = XMLParser(contentsOf: URL(fileURLWithPath: mapPath)) else {
            throw GameError.fileNotFound("Map: no se puede abrir \(mapPath)")
        }
        let base = (mapPath as NSString).deletingLastPathComponent
        let d = TilesetRefDelegate(base: base)
        parser.delegate = d
        let ok = parser.parse()
        withExtendedLifetime(d) {}
        guard ok else {
            throw GameError.parsingFailed("Map: error al parsear tilesets de \(mapPath)")
        }
        // Load each TSX *after* the TMX parser has fully finished — avoids reentrant XMLParser.
        for entry in d.collected {
            let ts = Tileset()
            ts.firstGid = entry.gid
            try ts.load(entry.path)
            addTileset(ts)
        }
    }

    private func readLayers(_ path: String) throws {
        guard let parser = XMLParser(contentsOf: URL(fileURLWithPath: path)) else {
            throw GameError.fileNotFound("Map: no se puede abrir \(path)")
        }
        let d = LayerDelegate(map: self)
        parser.delegate = d
        let ok = parser.parse()
        withExtendedLifetime(d) {}
        if !ok {
            throw GameError.parsingFailed("Map: error al parsear capas de \(path)")
        }
    }

    private func loadLayerInfo(paths: [String?]) {
        if Map.tilesetDebug == nil {
            let ts = Tileset()
            if let p = paths[Res.TLS_DEBUG] { try? ts.load(p) }
            Map.tilesetDebug = ts
        }

        while mapData.count <= Constants.infoLayer {
            mapData.append(Array(repeating: Array(repeating: 0, count: height),
                                count: width))
        }

        // Initialize the physical map and visibility map (double resolution)
        physicalTilesLayer  = Array(repeating: Array(repeating: 0, count: height * 2),
                                  count: width * 2)
        visibleTilesLayer = Array(repeating: Array(repeating: 0, count: height * 2),
                                  count: width * 2)

        for layer in 0..<maxLayers {
            for i in 0..<width {
                for j in 0..<height {
                    if let ts = getTileset(mapData[layer][i][j]),
                       ts.id != Res.TLS_UNIDADES {
                        let tsId = ts.id
                        mapData[Constants.infoLayer][i][j] = tsId
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
        try? PathFinder.shared.loadMap(self)
    }

    // MARK: - Helpers called from delegates

    fileprivate func addLayerName(name: String, index: Int) {
        layerNames[name] = index
        switch name.trimmingCharacters(in: .whitespaces).lowercased() {
        case "obstaculos": layers.obstacles = index
        case "terreno": layers.terrain = index
        case "unidades": layers.playerUnits = index
        case "posicion invalidada": layers.invalidatedPositions = index
        default: break
        }
    }

    fileprivate func addLayer(_ layerData: [[Int]]) {
        guard maxLayers < Constants.maxLayersCount else { return }
        while mapData.count <= maxLayers {
            mapData.append(Array(repeating: Array(repeating: 0, count: height),
                                count: width))
        }
        mapData[maxLayers] = layerData
        maxLayers += 1
    }

    fileprivate func addTileset(_ ts: Tileset) {
        guard tilesetCount < tilesets.count else { return }
        tilesets[tilesetCount] = ts
        tilesetCount += 1
    }

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
            width = Int(a["width"] ?? "0") ?? 0
            height = Int(a["height"] ?? "0") ?? 0
            tileWidth = Int(a["tilewidth"] ?? "0") ?? 0
            tileHeight = Int(a["tileheight"] ?? "0") ?? 0
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
    var collected: [(gid: Int, path: String)] = []

    init(base: String) {
        self.base = base
    }

    func parser(_ parser: XMLParser, didStartElement name: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes a: [String: String]) {
        guard name == "tileset", let src = a["source"] else { return }
        let gid = Int(a["firstgid"] ?? "0") ?? 0
        let candidate1 = (base as NSString).appendingPathComponent(src)
        let candidate2 = (ResourcePath.scenariosPath as NSString).appendingPathComponent(src)
        if let p = Utils.getPath(candidate1)
                ?? Utils.getPath(candidate2)
                ?? Utils.getPath(src) {
            collected.append((gid: gid, path: p))
        } else {
            Log.shared.error("Map: tileset not found \(src)")
        }
    }
}

private class LayerDelegate: NSObject, XMLParserDelegate {
    private weak var map: Map?
    private var layerName = ""
    private var layerIndex = 0
    private var inLayer = false
    private var inData = false
    private var encoding = ""
    private var dataBuffer = ""

    init(map: Map) { self.map = map }

    func parser(
        _ parser: XMLParser, didStartElement name: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes a: [String: String]) {
        if name == "layer" {
            layerName = a["name"] ?? ""
            inLayer = true
        } else if inLayer && name == "data" {
            encoding = a["encoding"] ?? ""
            inData = true
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
                    var tiles = Array(repeating: Array(repeating: 0, count: m.height),
                                      count: m.width)
                    let bytes = [UInt8](decoded)
                    var idx = 0
                    // TMX stores tiles row by row (row-major): first all columns
                    // of row 0, then those of row 1, etc.
                    for j in 0..<m.height {
                        for i in 0..<m.width {
                            if idx + 3 < bytes.count {
                                // 32-bit little-endian tile ID
                                let id = UInt32(bytes[idx])
                                    | UInt32(bytes[idx+1]) << 8
                                    | UInt32(bytes[idx+2]) << 16
                                    | UInt32(bytes[idx+3]) << 24
                                tiles[i][j] = Int(id & 0x1FFF) // flip bit mask (bits 29-31)
                            }
                            idx += 4
                        }
                    }
                    m.addLayerName(name: layerName, index: m.height == 0 ? 0 : layerIndex)
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
