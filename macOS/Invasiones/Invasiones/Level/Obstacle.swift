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
    private var m_index:    Int  = 0
    private var m_isBuilding: Bool = false

    // MARK: - Initializer
    init(index: Int, i: Int, j: Int, tileset: Tileset) {
        super.init()
        m_index = index

        m_frameHeight  = Int(tileset.tileHeight)
        m_frameWidth = Int(tileset.tileWidth)

        m_physicalTilePos = (i, j)
        m_image          = tileset.image

        let p = tileToWorld(i, j)
        m_worldPos = p

        if tileset.id == Int16(Res.TLS_EDIFICIOS) ||
           tileset.id == Int16(Res.TLS_ENFERMERIA) ||
           tileset.id == Int16(Res.TLS_FUERTE) {
            m_isBuilding = true
        }

        if tileset.id == Int16(Res.TLS_DEBUG) {
            m_image = nil
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
        guard let img = m_image, let map = MapObject.map else { return }
        img.setClip(m_index * m_frameWidth, 0, m_frameWidth, m_frameHeight)
        if m_isBuilding {
            g.draw(img, m_x, m_y - m_frameHeight + map.tileHeight / 2, 0)
        } else {
            g.draw(img,
                      m_x - m_frameWidth / 2 + map.tileWidth / 2,
                      m_y - m_frameHeight  + map.tileHeight / 2,
                      0)
        }
    }
}
