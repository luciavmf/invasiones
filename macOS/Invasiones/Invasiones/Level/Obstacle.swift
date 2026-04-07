//
//  Obstacle.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Obstaculo.cs — static obstacle on the map (tree, building, rock).
//

import Foundation

/// A static obstacle on the map (tree, building, rock, etc.) drawn from a tileset sprite sheet.
class Obstacle: MapObject {

    // MARK: - Declarations
    /// The frame index within the tileset image.
    private var index: Int = 0
    /// Whether the obstacle is a building, which changes how it is drawn.
    private var isBuilding: Bool = false

    // MARK: - Initializer
    /// Creates an obstacle from a tileset at tile position (i, j).
    /// - Parameters:
    ///   - idx: The frame index within the tileset.
    ///   - i: The tile column (i coordinate).
    ///   - j: The tile row (j coordinate).
    ///   - tileset: The tileset that contains this obstacle's image.
    init(index idx: Int, i: Int, j: Int, tileset: Tileset) {
        super.init()
        index = idx

        frameHeight = Int(tileset.tileHeight)
        frameWidth = Int(tileset.tileWidth)

        physicalTilePos = (i, j)
        image = tileset.image

        let p = tileToWorld(i: i, j: j)
        worldPos = p

        if tileset.id == Res.TLS_EDIFICIOS ||
           tileset.id == Res.TLS_ENFERMERIA ||
           tileset.id == Res.TLS_FUERTE {
            isBuilding = true
        }

        if tileset.id == Res.TLS_DEBUG {
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
        img.setClip(x: index * frameWidth, y: 0, w: frameWidth, h: frameHeight)
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
