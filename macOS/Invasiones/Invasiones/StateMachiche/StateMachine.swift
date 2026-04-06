//
//  StateMachine.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of MaquinaDeEstado.cs — generic game state machine.
//

import Foundation

/// Generic game state machine. Multiple instances can be created as needed.
class StateMachine {

    // MARK: - Declarations
    /// The current active state object.
    private var currentStateObj: State?
    /// The key of the current state.
    private(set) var currentState: GameFrame.STATE = .INVALID
    /// The previous state.
    private var prevState: State?
    /// The next state, queued for transition.
    private var nextState: State?
    /// The key of the next state.
    private var nextStateKey: GameFrame.STATE = .INVALID

    /// Dictionary of all registered states.
    private var allStates: [GameFrame.STATE: State?] = [:]

    // MARK: - Initializer
    init() {}

    deinit {
        dispose()
    }

    func dispose() {
        allStates.removeAll()
    }

    // MARK: - Methods
    /// Registers a state in the machine.
    func addState(_ key: GameFrame.STATE, _ state: State?) {
        allStates[key] = state
    }

    /// Queues the next state to transition into on the next update() call.
    func setNextState(_ key: GameFrame.STATE) {
        guard allStates.keys.contains(key) else {
            Log.shared.error("La maquina de estados no contiene la clave \(key)")
            return
        }
        nextState = allStates[key] ?? nil
        nextStateKey = key
    }

    /// Immediately switches to the given state (without calling salir/start).
    func setState(_ key: GameFrame.STATE) {
        prevState = currentStateObj
        currentStateObj = allStates[key] ?? nil
        currentState = key
    }

    /// Updates the machine: handles any pending transition and delegates to the current state.
    func update() {
        if let next = nextState {
            prevState = currentStateObj
            currentStateObj = next
            currentState = nextStateKey

            nextState = nil
            nextStateKey = .INVALID

            prevState?.exit()
            currentStateObj?.start()
        }

        currentStateObj?.update()
    }

    /// Draws the current state.
    func draw(_ g: Video) {
        currentStateObj?.draw(g)
    }
}
