//
//  Tileset.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Tileset.cs — loads and queries a TSX tileset (Tiled format).
//

import Foundation

class Tileset {

    // MARK: - Declarations
    var firstGid: Int16 = 0
    private(set) var id: Int16 = 0
    fileprivate(set) var tileWidth: Int16 = 0
    fileprivate(set) var tileHeight: Int16 = 0
    fileprivate(set) var name: String = "" {
        didSet {
            switch name.lowercased() {
            case "tierra":      id = Int16(Res.TLS_TIERRA)
            case "agua":        id = Int16(Res.TLS_AGUA)
            case "pasto":       id = Int16(Res.TLS_PASTO)
            case "arboles":     id = Int16(Res.TLS_ARBOLES)
            case "unidades":    id = Int16(Res.TLS_UNIDADES)
            case "piedras":     id = Int16(Res.TLS_PIEDRAS)
            case "texturas":    id = Int16(Res.TLS_TEXTURAS)
            case "piedras2":    id = Int16(Res.TLS_PIEDRAS2)
            case "enfermeria":  id = Int16(Res.TLS_ENFERMERIA)
            case "edificios":   id = Int16(Res.TLS_EDIFICIOS)
            case "invalidados": id = Int16(Res.TLS_INVALIDADO)
            case "fuerte":      id = Int16(Res.TLS_FUERTE)
            default: break
            }
        }
    }
    fileprivate(set) var image: Surface? {
        didSet {
            if let img = image, tileWidth > 0, tileHeight > 0 {
                let count = (img.height / Int(tileHeight)) * (img.width / Int(tileWidth))
                tiles = Array(repeating: nil, count: count)
            }
        }
    }
    var tiles: [Tile?] = []

    // MARK: - Initializer
    init() {}

    // MARK: - Loading

    /// Loads the tileset from the given TSX path.
    @discardableResult
    func load(_ tilesetPath: String) -> Bool {
        guard let parser = XMLParser(contentsOf: URL(fileURLWithPath: tilesetPath)) else {
            Log.shared.error("Tileset: no se puede abrir \(tilesetPath)")
            return false
        }
        let delegate = TilesetXMLDelegate(tileset: self, basePath: tilesetPath)
        parser.delegate = delegate
        let ok = parser.parse()
        withExtendedLifetime(delegate) {}
        return ok
    }

    // MARK: - Helpers

    /// Returns the (x, y, w, h) rectangle within the tileset image for the given tile.
    func getTileRect(_ tileId: Int) -> (x: Int, y: Int, w: Int, h: Int) {
        guard let img = image, tileWidth > 0, tileHeight > 0 else { return (0, 0, 0, 0) }
        let cols = img.width / Int(tileWidth)
        let col = cols > 0 ? tileId % cols : 0
        let row = cols > 0 ? tileId / cols : 0
        return (col * Int(tileWidth), row * Int(tileHeight),
                Int(tileWidth), Int(tileHeight))
    }

}

// MARK: - Internal XML parser

private class TilesetXMLDelegate: NSObject, XMLParserDelegate {

    private weak var tileset: Tileset?
    private let basePath: String
    private var currentTileId: Int = -1

    init(tileset: Tileset, basePath: String) {
        self.tileset = tileset
        self.basePath = (basePath as NSString).deletingLastPathComponent
    }

    func parser(_ parser: XMLParser, didStartElement name: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes: [String: String]) {
        guard let ts = tileset else { return }

        switch name {
        case "tileset":
            if let n = attributes["name"] { ts.name = n }
            if let w = attributes["tilewidth"]  { ts.tileWidth  = Int16(w) ?? 0 }
            if let h = attributes["tileheight"] { ts.tileHeight = Int16(h) ?? 0 }

        case "image":
            if let src = attributes["source"] {
                let fullPath = Utils.getPath(
                    (basePath as NSString).appendingPathComponent(src))
                    ?? Utils.getPath(
                        (Program.SCENARIOS_PATH as NSString).appendingPathComponent(src))
                if let path = fullPath {
                    ts.image = ResourceManager.shared.getImage(path)
                } else {
                    Log.shared.error("Tileset: no se encuentra image \(src)")
                }
            }

        case "tile":
            if let idStr = attributes["id"], let idx = Int(idStr) {
                currentTileId = idx
                if idx < ts.tiles.count {
                    ts.tiles[idx] = Tile()
                }
            }

        case "property":
            guard currentTileId >= 0, currentTileId < ts.tiles.count else { break }
            let propName = (attributes["name"] ?? "").lowercased()
            let propValue = attributes["value"] ?? ""
            if propName == "id" || propName == "unidad" {
                switch propValue {
                case "TILES_VECINOS":    ts.tiles[currentTileId]?.id = Int16(Res.TILE_DEBUG_ID_TILES_VECINOS)
                case "CAMINO_A_SEGUIR": ts.tiles[currentTileId]?.id = Int16(Res.TILE_DEBUG_ID_CAMINO_A_SEGUIR)
                case "PATRICIO":        ts.tiles[currentTileId]?.id = Int16(Res.TILE_UNIDADES_ID_PATRICIO)
                case "ENFERMERIA":      ts.tiles[currentTileId]?.id = Int16(Res.TILE_INVALIDADOS_ID_ENFERMERIA)
                case "CASA":            ts.tiles[currentTileId]?.id = Int16(Res.TILE_INVALIDADOS_ID_CASA)
                case "INGLES":          ts.tiles[currentTileId]?.id = Int16(Res.TILE_UNIDADES_ID_INGLES)
                default: break
                }
            } else if propName == "cantidad" {
                ts.tiles[currentTileId]?.count = Int(propValue) ?? 0
            }

        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement name: String,
                namespaceURI: String?, qualifiedName: String?) {
        if name == "tile" { currentTileId = -1 }
    }
}
