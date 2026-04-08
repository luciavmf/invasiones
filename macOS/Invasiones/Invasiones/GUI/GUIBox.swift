//
//  GUIBox.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of CajaGUI.cs — abstract base class for all GUI components.
//

import Foundation

class GUIBox {

    // MARK: - Declarations
    var posY: Int = 0
    var posX: Int = 0
    var font: GameFont?
    var width: Int = 0
    var height: Int = 0
    var image: Surface?
    var label: Int = 0

    // MARK: - Initializer
    init() {}

    // MARK: - Abstract methods
    func setPosition(x: Int, y: Int, anchor: Int) {
        fatalError("\(type(of: self)).setPosition must be overridden")
    }

    @discardableResult
    func update() -> Int {
        fatalError("\(type(of: self)).update must be overridden")
    }

    func draw(_ video: Video) {
        fatalError("\(type(of: self)).draw must be overridden")
    }
}
