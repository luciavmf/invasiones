//
//  MapObject.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Objeto.cs — base class for all map objects (obstacles, units, animations).
//

import Foundation

class MapObject {

    // MARK: - Shared statics (equivalent to static fields in C#)
    static var camera: Camera?
    static var map: Map?

    // MARK: - Attributes
    var image:            Surface?
    var worldPos:         (x: Int, y: Int) = (0, 0)
    var physicalTilePos:  (x: Int, y: Int) = (0, 0)
    var previousTile:     (x: Int, y: Int) = (0, 0)
    var frameWidth:       Int = 0
    var frameHeight:      Int = 0
    var x:                Int = 0
    var y:                Int = 0

    // MARK: - Public properties
    var worldPosFlat: (x: Int, y: Int) { worldPos }

    // MARK: - Initializeres

    init() {}

    init(sup: Surface?, i: Int, j: Int) {
        self.image = sup
        if let img = sup {
            frameHeight = img.height
            frameWidth = img.width
        }
        physicalTilePos = (i, j)
        let p = tileToWorld(i, j)
        worldPos = p
    }

    // MARK: - Methods

    @discardableResult
    func update() -> Bool {
        updateScreenPos()
        return false
    }

    func updateScreenPos() {
        guard let cam = MapObject.camera else { return }
        x = cam.startX + worldPos.x + cam.X
        y = cam.startY + worldPos.y + cam.Y
    }

    func draw(_ g: Video) {
        guard let img = image, let map = MapObject.map else { return }
        g.draw(
            img,
            x - frameWidth / 2 + map.tileWidth / 2,
            y - frameHeight  + map.tileHeight  / 4,
            0)
    }

    /// Transforms tile (i, j) into (x, y) position in the flat world.
    func tileToWorld(_ i: Int, _ j: Int) -> (x: Int, y: Int) {
        guard let map = MapObject.map else { return (0, 0) }
        let x = ((i - j) * map.tileWidth / 2) >> 1
        let y = ((i + j) * map.tileHeight  / 2) >> 1
        return (x, y)
    }

    func setTilePosition(_ i: Int, _ j: Int) {
        physicalTilePos = (i, j)
        let p = tileToWorld(i, j)
        worldPos = p
        updateScreenPos()
    }

    // Initializes x, y from the current tile position (called when creating the unit).
    func initializeXY() {
        let p = tileToWorld(physicalTilePos.x, physicalTilePos.y)
        worldPos = p
        updateScreenPos()
    }
}
