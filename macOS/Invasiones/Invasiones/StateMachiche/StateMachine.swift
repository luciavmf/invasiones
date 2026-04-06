//
//  StateMachine.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of MaquinaDeEstado.cs — generic game state machine.
//

import Foundation

class StateMachine {

    // MARK: - Declarations
    private var m_currentState: State?
    private var m_currentStateKey: GameFrame.STATE = .INVALID
    private var m_prevState: State?
    private var m_nextState: State?
    private var m_nextStateKey: GameFrame.STATE = .INVALID

    /// Dictionary of all registered states.
    private var m_allStates: [GameFrame.STATE: State?] = [:]

    // MARK: - Properties
    var currentState: GameFrame.STATE { m_currentStateKey }

    // MARK: - Initializer
    init() {}

    deinit {
        dispose()
    }

    func dispose() {
        m_allStates.removeAll()
    }

    // MARK: - Methods
    /// Registers a state in the machine.
    func addState(_ key: GameFrame.STATE, _ state: State?) {
        m_allStates[key] = state
    }

    /// Queues the next state to transition into on the next update() call.
    func setNextState(_ key: GameFrame.STATE) {
        guard m_allStates.keys.contains(key) else {
            Log.shared.error("La maquina de estados no contiene la clave \(key)")
            return
        }
        m_nextState = m_allStates[key] ?? nil
        m_nextStateKey = key
    }

    /// Immediately switches to the given state (without calling salir/start).
    func setState(_ key: GameFrame.STATE) {
        m_prevState = m_currentState
        m_currentState = m_allStates[key] ?? nil
        m_currentStateKey = key
    }

    /// Updates the machine: handles any pending transition and delegates to the current state.
    func update() {
        if let next = m_nextState {
            m_prevState = m_currentState
            m_currentState = next
            m_currentStateKey = m_nextStateKey

            m_nextState = nil
            m_nextStateKey = .INVALID

            m_prevState?.exit()
            m_currentState?.start()
        }

        m_currentState?.update()
    }

    /// Draws the current state.
    func draw(_ g: Video) {
        m_currentState?.draw(g)
    }
}
