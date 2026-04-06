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
    static var map:   Map?

    // MARK: - Attributes
    var m_image:            Surface?
    var m_worldPos:   (x: Int, y: Int) = (0, 0)
    var m_physicalTilePos:   (x: Int, y: Int) = (0, 0)
    var m_previousTilePos: (x: Int, y: Int) = (0, 0)
    var m_frameWidth:        Int = 0
    var m_frameHeight:         Int = 0
    var m_x:                 Int = 0
    var m_y:                 Int = 0

    // MARK: - Public properties
    var physicalTilePos: (x: Int, y: Int) {
        get { m_physicalTilePos }
        set { m_physicalTilePos = newValue }
    }

    var previousTile: (x: Int, y: Int) {
        get { m_previousTilePos }
        set { m_previousTilePos = newValue }
    }

    var worldPosFlat: (x: Int, y: Int) { m_worldPos }

    // MARK: - Initializeres

    init() {}

    init(sup: Surface?, i: Int, j: Int) {
        m_image = sup
        if let img = sup {
            m_frameHeight  = img.height
            m_frameWidth = img.width
        }
        m_physicalTilePos = (i, j)
        let p = tileToWorld(i, j)
        m_worldPos = p
    }

    // MARK: - Methods

    @discardableResult
    func update() -> Bool {
        updateScreenPos()
        return false
    }

    func updateScreenPos() {
        guard let cam = MapObject.camera else { return }
        m_x = cam.startX + m_worldPos.x + cam.X
        m_y = cam.startY + m_worldPos.y + cam.Y
    }

    func draw(_ g: Video) {
        guard let img = m_image, let map = MapObject.map else { return }
        g.draw(img,
                  m_x - m_frameWidth / 2 + map.tileWidth / 2,
                  m_y - m_frameHeight  + map.tileHeight  / 4,
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
        m_physicalTilePos = (i, j)
        let p = tileToWorld(i, j)
        m_worldPos = p
        updateScreenPos()
    }

    // Initializes m_x, m_y from the current tile position (called when creating the unit).
    func initializeXY() {
        let p = tileToWorld(m_physicalTilePos.x, m_physicalTilePos.y)
        m_worldPos = p
        updateScreenPos()
    }
}
