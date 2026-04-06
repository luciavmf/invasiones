// Map/Tileset.swift
// Puerto de Tileset.cs — carga y consulta de un tileset TSX (formato Tiled).

import Foundation

class Tileset {

    // MARK: - Declaraciones
    var primerGid:    Int16 = 0
    private var m_nombre:    String = ""
    private(set) var id:     Int16  = 0
    private(set) var anchoDelTile: Int16 = 0
    private(set) var altoDelTile:  Int16 = 0
    private(set) var imagen: Superficie?
    var tiles:  [Tile?] = []

    // MARK: - Constructor
    init() {}

    // MARK: - Carga

    /// Carga el tileset desde el path TSX dado.
    @discardableResult
    func cargar(_ tilesetPath: String) -> Bool {
        guard let parser = XMLParser(contentsOf: URL(fileURLWithPath: tilesetPath)) else {
            Log.Instancia.error("Tileset: no se puede abrir \(tilesetPath)")
            return false
        }
        let delegate = TilesetXMLDelegate(tileset: self, basePath: tilesetPath)
        parser.delegate = delegate
        return parser.parse()
    }

    // MARK: - Helpers

    /// Devuelve el rectángulo (x, y, w, h) dentro de la imagen del tileset para el tile dado.
    func obtenerRectanguloDelTile(_ tileId: Int) -> (x: Int, y: Int, w: Int, h: Int) {
        guard let img = imagen, altoDelTile > 0 else { return (0, 0, 0, 0) }
        let filas = img.alto / Int(altoDelTile)
        let fila   = filas > 0 ? tileId % filas : 0
        let col    = filas > 0 ? tileId / filas : 0
        return (col * Int(anchoDelTile), fila * Int(anchoDelTile),
                Int(anchoDelTile), Int(altoDelTile))
    }

    /// Asigna el nombre e infiere el ID numérico.
    func setearNombre(_ nombre: String) {
        m_nombre = nombre
        switch nombre.lowercased() {
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

    func setearAnchoTile(_ v: Int16) { anchoDelTile = v }
    func setearAltoTile(_ v: Int16)  { altoDelTile  = v }

    func setearImagen(_ sup: Superficie?) {
        imagen = sup
        if let img = sup, anchoDelTile > 0, altoDelTile > 0 {
            let count = (img.alto / Int(altoDelTile)) * (img.ancho / Int(anchoDelTile))
            tiles = Array(repeating: nil, count: count)
        }
    }
}

// MARK: - Parser XML interno

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
            if let n = attributes["name"] { ts.setearNombre(n) }
            if let w = attributes["tilewidth"]  { ts.setearAnchoTile(Int16(w) ?? 0) }
            if let h = attributes["tileheight"] { ts.setearAltoTile(Int16(h)  ?? 0) }

        case "image":
            if let src = attributes["source"] {
                let fullPath = Utilidades.obtenerPath(
                    (basePath as NSString).appendingPathComponent(src))
                    ?? Utilidades.obtenerPath(
                        (Programa.PATH_ESCENARIOS as NSString).appendingPathComponent(src))
                if let path = fullPath {
                    ts.setearImagen(AdministradorDeRecursos.Instancia.obtenerImagen(path))
                } else {
                    Log.Instancia.error("Tileset: no se encuentra imagen \(src)")
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
            let propName  = (attributes["name"]  ?? "").lowercased()
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
                ts.tiles[currentTileId]?.cantidad = Int(propValue) ?? 0
            }

        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement name: String,
                namespaceURI: String?, qualifiedName: String?) {
        if name == "tile" { currentTileId = -1 }
    }
}
