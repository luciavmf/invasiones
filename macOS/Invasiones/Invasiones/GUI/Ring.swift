//
//  Ring.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Aro.cs — animated ring indicating the current objective on the map.
//

import Foundation

class Ring: MapObject {

    // MARK: - Declarations
    private let m_animacion: Animation

    // MARK: - Initializer
    init(_ anim: Animation, _ i: Int, _ j: Int) {
        m_animacion = anim
        super.init()

        m_physicalTilePos = (i, j)
        let p = tileToWorld(i, j)
        m_worldPos = p

        m_animacion.load()
        updateScreenPos()

        m_worldPos.x -= m_animacion.offsets.x
        m_worldPos.y -= m_animacion.offsets.y

        m_animacion.play()
        m_animacion.loop = true
    }

    // MARK: - Override

    @discardableResult
    override func update() -> Bool {
        super.update()
        m_animacion.update()
        return false
    }

    override func draw(_ g: Video) {
        guard let map = MapObject.map else { return }
        m_animacion.draw(g, m_x + map.tileWidth / 2, m_y + map.tileHeight / 2, 0)
    }

    // MARK: - Own methods

    func setPosition(_ i: Int, _ j: Int) {
        m_physicalTilePos = (i, j)
        let p = tileToWorld(i, j)
        m_worldPos = p
        m_worldPos.x -= m_animacion.offsets.x
        m_worldPos.y -= m_animacion.offsets.y
        updateScreenPos()
    }
}
