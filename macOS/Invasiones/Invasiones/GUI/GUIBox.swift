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
    var m_y:       Int = 0
    var m_x:       Int = 0
    var m_font:  GameFont?
    var m_width:   Int = 0
    var m_height:    Int = 0
    var m_image:  Surface?
    var m_label: Int = 0

    // MARK: - Properties
    var height:  Int { m_height  }
    var width: Int { m_width }

    // MARK: - Initializer
    init() {}

    // MARK: - Abstract methods
    func setPosition(_ x: Int, _ y: Int, _ anchor: Int) {
        fatalError("\(type(of: self)).setPosition must be overridden")
    }

    @discardableResult
    func update() -> Int {
        fatalError("\(type(of: self)).update must be overridden")
    }

    func draw(_ g: Video) {
        fatalError("\(type(of: self)).draw must be overridden")
    }
}
