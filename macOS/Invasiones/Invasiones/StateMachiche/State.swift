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

/// Abstract base class from which all game states derive.
class State {

    // MARK: - Declarations
    /// Parent state machine — needed to transition to another state from within.
    var stateMachine: StateMachine

    /// Background image for this state (loaded in start(), drawn in draw()).
    var background: Surface?

    /// Generic button reused by several states (e.g. "Menu", "Next").
    var button: Button?

    /// Used for countdowns.
    var count: Int = 0

    // MARK: - Initializer
    /// - Parameter sm: The parent state machine, required for triggering state transitions from within the state.
    init(_ sm: StateMachine) {
        self.stateMachine = sm
    }

    // MARK: - Abstract methods (must be overridden by subclasses)
    /// Draws the state onto the given video surface.
    /// - Parameter video: The screen to draw onto.
    func draw(_ video: Video) {
        fatalError("\(type(of: self)).draw(_:) must be overridden")
    }

    /// Updates the state logic for this frame.
    func update() {
        fatalError("\(type(of: self)).update() must be overridden")
    }

    /// Called each time this state becomes active.
    func start() {
        fatalError("\(type(of: self)).start() must be overridden")
    }

    /// Called each time this state is exited.
    func exit() {
        fatalError("\(type(of: self)).salir() must be overridden")
    }
}
