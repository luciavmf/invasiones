//
//  MapObject.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Objeto.cs — base class for all map objects (obstacles, units, animations).
//

import Foundation

/// Base class for all drawable map objects: obstacles, units, and animations.
/// Stores position in tile space and derived screen-space coordinates used for rendering.
class MapObject {

    // MARK: - Shared statics (equivalent to static fields in C#)
    /// The camera used by all map objects to convert world positions to screen positions.
    static var camera: Camera?
    /// The map shared by all map objects (used for tile/world coordinate conversion).
    static var map: Map?

    // MARK: - Attributes
    /// The image (sprite sheet) used to draw this object.
    var image:            Surface?
    /// Position in the flat (isometric-projected) world coordinate system.
    var worldPos:         (x: Int, y: Int) = (0, 0)
    /// Current tile position on the physical (2× resolution) grid.
    var physicalTilePos:  (x: Int, y: Int) = (0, 0)
    /// The tile the object occupied on the previous frame (used to update the object map).
    var previousTile:     (x: Int, y: Int) = (0, 0)
    /// Width of a single animation frame in pixels.
    var frameWidth:       Int = 0
    /// Height of a single animation frame in pixels.
    var frameHeight:      Int = 0
    /// Screen x coordinate where this object will be drawn.
    var x:                Int = 0
    /// Screen y coordinate where this object will be drawn.
    var y:                Int = 0

    // MARK: - Public properties
    /// The flat world position (alias for worldPos).
    var worldPosFlat: (x: Int, y: Int) { worldPos }

    // MARK: - Initializeres

    init() {}

    /// Creates a map object at tile position (i, j) using the given surface.
    /// - Parameters:
    ///   - sup: The image (or sprite sheet) for this object.
    ///   - i: Tile column (i coordinate).
    ///   - j: Tile row (j coordinate).
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

    /// Recalculates the screen-space (x, y) coordinates from the current camera and world position.
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

    /// Sets the object's tile position and immediately recalculates world and screen coordinates.
    /// - Parameters:
    ///   - i: New tile column.
    ///   - j: New tile row.
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
