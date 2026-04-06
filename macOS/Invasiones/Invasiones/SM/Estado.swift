//
//  Estado.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Estado.cs — abstract base class for all game states.
//  Swift uses fatalError() to simulate abstract methods.
//

import Foundation

class Estado {

    // MARK: - Declarations
    /// Parent state machine — needed to transition to another state from within.
    var maquinaDeEstados: MaquinaDeEstados

    /// Background image for this state (loaded in iniciar(), drawn in dibujar()).
    var m_fondo: Superficie?

    /// Generic button reused by several states (e.g. "Menu", "Next").
    var m_boton: Boton?

    /// Used for countdowns.
    var m_cuenta: Int = 0

    // MARK: - Initializer
    init(_ sm: MaquinaDeEstados) {
        self.maquinaDeEstados = sm
    }

    // MARK: - Abstract methods (must be overridden by subclasses)
    func dibujar(_ g: Video) {
        fatalError("\(type(of: self)).dibujar(_:) must be overridden")
    }

    func actualizar() {
        fatalError("\(type(of: self)).actualizar() must be overridden")
    }

    func iniciar() {
        fatalError("\(type(of: self)).iniciar() must be overridden")
    }

    func salir() {
        fatalError("\(type(of: self)).salir() must be overridden")
    }
}
