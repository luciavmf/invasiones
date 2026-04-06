//
//  AnimObject.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of AnimObjeto.cs — animated object positioned on a map tile (fire, etc.).
//

import Foundation

class AnimObject: MapObject {

    // MARK: - Declarations
    private(set) var animation: Animation

    // MARK: - Initializer
    init(_ anim: Animation, _ i: Int, _ j: Int) {
        animation = anim
        super.init()

        m_physicalTilePos = (i, j)
        let p = tileToWorld(i, j)
        m_worldPos = p

        animation.load()
        updateScreenPos()

        m_worldPos.x -= animation.offsets.x
        m_worldPos.y -= animation.offsets.y

        animation.play()
        animation.loop = true
    }

    // MARK: - Override

    @discardableResult
    override func update() -> Bool {
        super.update()
        animation.update()
        return false
    }

    override func draw(_ g: Video) {
        guard let map = MapObject.map else { return }
        if m_worldPos.x == -1 || m_worldPos.y == -1 { return }
        animation.draw(g, m_x + map.tileWidth / 2, m_y + map.tileHeight / 2, 0)
    }

    // MARK: - Own methods

    func setAnimation(_ anim: Int) {
        animation.setAnimation(anim)
    }

    func setPosition(_ i: Int, _ j: Int) {
        m_physicalTilePos = (i, j)
        let p = tileToWorld(i, j)
        m_worldPos = p
        m_worldPos.x -= animation.offsets.x
        m_worldPos.y -= animation.offsets.y
        updateScreenPos()
    }
}
