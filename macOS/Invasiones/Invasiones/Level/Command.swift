//
//  Command.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Orden.cs — represents an order a unit or group must carry out.
//

import Foundation

/// Represents a single order that a unit or group must carry out (move, attack, heal, etc.).
class Command {

    /// The type of order that can be issued to a unit or group.
    enum TYPE: Int {
        case INVALID = -1
        case TAKE_OBJECT = 0
        case MOVE
        case ATTACK
        case PATROL
        case HEAL
        case TRIGGER
        case KILL
    }

    // MARK: - Declarations
    /// The command type identifier.
    private(set) var id: TYPE
    /// The tile position where the command must be fulfilled.
    private(set) var point: (x: Int, y: Int)
    /// The image of the object to pick up (only for TAKE_OBJECT commands).
    private(set) var image: Surface?
    /// The fire animation to play at the trigger point (only for TRIGGER commands).
    private(set) var animation: AnimObject?
    /// Width of the kill zone in tiles (only for KILL commands).
    private(set) var width: Int = 0

    // MARK: - Initializeres

    /// Creates a command at the given tile position.
    /// - Parameters:
    ///   - type: The command type.
    ///   - x: Tile x coordinate where the command must be fulfilled.
    ///   - y: Tile y coordinate where the command must be fulfilled.
    init(_ type: TYPE, _ x: Int, _ y: Int) {
        id = type
        point = (x, y)
    }

    /// Creates a KILL command with a square kill zone of the given half-width.
    init(_ type: TYPE, _ x: Int, _ y: Int, _ widthParam: Int) {
        id = type
        point = (x, y)
        width = widthParam
    }

    /// Creates a TAKE_OBJECT command that loads the image to collect from a path.
    init(_ type: TYPE, _ x: Int, _ y: Int, _ path: String) {
        id = type
        point = (x, y)
        if let p = Utils.getPath(path) {
            image = ResourceManager.shared.getImage(p)
        }
        if image == nil {
            Log.shared.debug("No se puede obtener la image que esta en el nivel: \(path)")
        }
    }

    /// Creates a TRIGGER command with an animation to display at the trigger point.
    init(_ type: TYPE, _ x: Int, _ y: Int, _ anim: AnimObject?) {
        id = type
        point = (x, y)
        animation = anim
    }
}
