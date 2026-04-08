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
        let p = tileToWorld(i: i, j: j)
        worldPos = p

        try? animation.load()
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

    override func draw(_ video: Video) {
        guard let map = MapObject.map else { return }
        if worldPos.x == -1 || worldPos.y == -1 { return }
        animation.draw(video: video, x: x + map.tileWidth / 2, y: y + map.tileHeight / 2, anchor: 0)
    }

    // MARK: - Own methods

    func setAnimation(anim: Int) {
        animation.setAnimation(anim: anim)
    }

    func setPosition(i: Int, j: Int) {
        physicalTilePos = (i, j)
        let p = tileToWorld(i: i, j: j)
        worldPos = p
        worldPos.x -= animation.offsets.x
        worldPos.y -= animation.offsets.y
        updateScreenPos()
    }
}
