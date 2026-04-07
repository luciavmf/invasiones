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
    private let animacion: Animation

    // MARK: - Initializer
    init(_ anim: Animation, _ i: Int, _ j: Int) {
        animacion = anim
        super.init()

        physicalTilePos = (i, j)
        let p = tileToWorld(i: i, j: j)
        worldPos = p

        animacion.load()
        updateScreenPos()

        worldPos.x -= animacion.offsets.x
        worldPos.y -= animacion.offsets.y

        animacion.play()
        animacion.loop = true
    }

    // MARK: - Override

    @discardableResult
    override func update() -> Bool {
        super.update()
        animacion.update()
        return false
    }

    override func draw(_ g: Video) {
        guard let map = MapObject.map else { return }
        animacion.draw(g: g, x: x + map.tileWidth / 2, y: y + map.tileHeight / 2, anchor: 0)
    }

    // MARK: - Own methods

    func setPosition(i: Int, j: Int) {
        physicalTilePos = (i, j)
        let p = tileToWorld(i: i, j: j)
        worldPos = p
        worldPos.x -= animacion.offsets.x
        worldPos.y -= animacion.offsets.y
        updateScreenPos()
    }
}
