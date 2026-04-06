//
//  Obstacle.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Obstaculo.cs — static obstacle on the map (tree, building, rock).
//

import Foundation

class Obstacle: MapObject {

    // MARK: - Declarations
    private var index: Int = 0
    private var isBuilding: Bool = false

    // MARK: - Initializer
    init(index idx: Int, i: Int, j: Int, tileset: Tileset) {
        super.init()
        index = idx

        frameHeight = Int(tileset.tileHeight)
        frameWidth = Int(tileset.tileWidth)

        physicalTilePos = (i, j)
        image = tileset.image

        let p = tileToWorld(i, j)
        worldPos = p

        if tileset.id == Int16(Res.TLS_EDIFICIOS) ||
           tileset.id == Int16(Res.TLS_ENFERMERIA) ||
           tileset.id == Int16(Res.TLS_FUERTE) {
            isBuilding = true
        }

        if tileset.id == Int16(Res.TLS_DEBUG) {
            image = nil
        }

        updateScreenPos()
    }

    // MARK: - Override

    @discardableResult
    override func update() -> Bool {
        updateScreenPos()
        return false
    }

    override func draw(_ g: Video) {
        guard let img = image, let map = MapObject.map else { return }
        img.setClip(index * frameWidth, 0, frameWidth, frameHeight)
        if isBuilding {
            g.draw(img, x, y - frameHeight + map.tileHeight / 2, 0)
        } else {
            g.draw(img,
                      x - frameWidth / 2 + map.tileWidth / 2,
                      y - frameHeight  + map.tileHeight / 2,
                      0)
        }
    }
}
