//
//  State.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Estado.cs — abstract base class for all game states.
//  Swift uses fatalError() to simulate abstract methods.
//

import Foundation

class State {

    // MARK: - Declarations
    /// Parent state machine — needed to transition to another state from within.
    var stateMachine: StateMachine

    /// Background image for this state (loaded in start(), drawn in draw()).
    var m_background: Surface?

    /// Generic button reused by several states (e.g. "Menu", "Next").
    var m_button: Button?

    /// Used for countdowns.
    var m_count: Int = 0

    // MARK: - Initializer
    init(_ sm: StateMachine) {
        self.stateMachine = sm
    }

    // MARK: - Abstract methods (must be overridden by subclasses)
    func draw(_ g: Video) {
        fatalError("\(type(of: self)).draw(_:) must be overridden")
    }

    func update() {
        fatalError("\(type(of: self)).update() must be overridden")
    }

    func start() {
        fatalError("\(type(of: self)).start() must be overridden")
    }

    func exit() {
        fatalError("\(type(of: self)).salir() must be overridden")
    }
}
