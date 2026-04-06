//
//  CajaGUI.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of CajaGUI.cs — abstract base class for all GUI components.
//

import Foundation

class CajaGUI {

    // MARK: - Declarations
    var m_y:       Int = 0
    var m_x:       Int = 0
    var m_fuente:  Fuente?
    var m_ancho:   Int = 0
    var m_alto:    Int = 0
    var m_imagen:  Superficie?
    var m_leyenda: Int = 0

    // MARK: - Properties
    var alto:  Int { m_alto  }
    var ancho: Int { m_ancho }

    // MARK: - Initializer
    init() {}

    // MARK: - Abstract methods
    func setearPosicion(_ x: Int, _ y: Int, _ ancla: Int) {
        fatalError("\(type(of: self)).setearPosicion must be overridden")
    }

    @discardableResult
    func actualizar() -> Int {
        fatalError("\(type(of: self)).actualizar must be overridden")
    }

    func dibujar(_ g: Video) {
        fatalError("\(type(of: self)).dibujar must be overridden")
    }
}
