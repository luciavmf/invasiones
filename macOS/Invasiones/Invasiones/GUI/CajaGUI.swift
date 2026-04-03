// GUI/CajaGUI.swift
// Puerto de CajaGUI.cs — clase base abstracta de todos los componentes GUI.

import Foundation

class CajaGUI {

    // MARK: - Declaraciones
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

    // MARK: - Constructor
    init() {}

    // MARK: - Métodos abstractos
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
