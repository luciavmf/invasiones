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

        physicalTilePos = (i, j)
        let p = tileToWorld(i, j)
        worldPos = p

        animation.load()
        updateScreenPos()

        worldPos.x -= animation.offsets.x
        worldPos.y -= animation.offsets.y

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
        if worldPos.x == -1 || worldPos.y == -1 { return }
        animation.draw(g, x + map.tileWidth / 2, y + map.tileHeight / 2, 0)
    }

    // MARK: - Own methods

    func setAnimation(_ anim: Int) {
        animation.setAnimation(anim)
    }

    func setPosition(_ i: Int, _ j: Int) {
        physicalTilePos = (i, j)
        let p = tileToWorld(i, j)
        worldPos = p
        worldPos.x -= animation.offsets.x
        worldPos.y -= animation.offsets.y
        updateScreenPos()
    }
}
