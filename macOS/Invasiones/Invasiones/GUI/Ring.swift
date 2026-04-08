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
    private let animation: Animation

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
        animation.draw(video: video, x: x + map.tileWidth / 2, y: y + map.tileHeight / 2, anchor: 0)
    }

    // MARK: - Own methods

    func setPosition(i: Int, j: Int) {
        physicalTilePos = (i, j)
        let p = tileToWorld(i: i, j: j)
        worldPos = p
        worldPos.x -= animation.offsets.x
        worldPos.y -= animation.offsets.y
        updateScreenPos()
    }
}
