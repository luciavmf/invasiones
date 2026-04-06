//
//  MaquinaDeEstados.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of MaquinaDeEstados.cs — generic game state machine.
//

import Foundation

class MaquinaDeEstados {

    // MARK: - Declarations
    private var m_estadoActual: Estado?
    private var m_keyEstadoActual: GameFrame.ESTADO = .INVALIDO
    private var m_estadoPrevio: Estado?
    private var m_proximoEstado: Estado?
    private var m_keyProximoEstado: GameFrame.ESTADO = .INVALIDO

    /// Dictionary of all registered states.
    private var m_todosLosEstados: [GameFrame.ESTADO: Estado?] = [:]

    // MARK: - Properties
    var estadoActual: GameFrame.ESTADO { m_keyEstadoActual }

    // MARK: - Initializer
    init() {}

    deinit {
        dispose()
    }

    func dispose() {
        m_todosLosEstados.removeAll()
    }

    // MARK: - Methods
    /// Registers a state in the machine.
    func agregarEstado(_ key: GameFrame.ESTADO, _ estado: Estado?) {
        m_todosLosEstados[key] = estado
    }

    /// Queues the next state to transition into on the next actualizar() call.
    func setearElProximoEstado(_ key: GameFrame.ESTADO) {
        guard m_todosLosEstados.keys.contains(key) else {
            Log.Instancia.error("La maquina de estados no contiene la clave \(key)")
            return
        }
        m_proximoEstado = m_todosLosEstados[key] ?? nil
        m_keyProximoEstado = key
    }

    /// Immediately switches to the given state (without calling salir/iniciar).
    func setearEstado(_ key: GameFrame.ESTADO) {
        m_estadoPrevio = m_estadoActual
        m_estadoActual = m_todosLosEstados[key] ?? nil
        m_keyEstadoActual = key
    }

    /// Updates the machine: handles any pending transition and delegates to the current state.
    func actualizar() {
        if let proximo = m_proximoEstado {
            m_estadoPrevio = m_estadoActual
            m_estadoActual = proximo
            m_keyEstadoActual = m_keyProximoEstado

            m_proximoEstado = nil
            m_keyProximoEstado = .INVALIDO

            m_estadoPrevio?.salir()
            m_estadoActual?.iniciar()
        }

        m_estadoActual?.actualizar()
    }

    /// Draws the current state.
    func dibujar(_ g: Video) {
        m_estadoActual?.dibujar(g)
    }
}
