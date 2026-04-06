//
//  Command.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Orden.cs — represents an order a unit or group must carry out.
//

import Foundation

class Command {

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
    private(set) var id: TYPE
    private(set) var point:     (x: Int, y: Int)
    private(set) var image:    Surface?
    private(set) var animation: AnimObject?
    private(set) var width:     Int = 0

    // MARK: - Initializeres

    init(_ type: TYPE, _ x: Int, _ y: Int) {
        id    = type
        point = (x, y)
    }

    init(_ type: TYPE, _ x: Int, _ y: Int, _ widthParam: Int) {
        id    = type
        point = (x, y)
        width = widthParam
    }

    init(_ type: TYPE, _ x: Int, _ y: Int, _ path: String) {
        id    = type
        point = (x, y)
        if let p = Utils.getPath(path) {
            image = ResourceManager.shared.getImage(p)
        }
        if image == nil {
            Log.shared.debug("No se puede obtener la image que esta en el nivel: \(path)")
        }
    }

    init(_ type: TYPE, _ x: Int, _ y: Int, _ anim: AnimObject?) {
        id        = type
        point     = (x, y)
        animation = anim
    }
}
