//
//  Objective.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Objetivo.cs — represents an objective to fulfill (stack of orders).
//

import Foundation

/// Represents a level objective: a stack of commands that must be fulfilled in order to advance.
struct Objective {

    // MARK: - Declarations
    /// The ordered list of commands that make up this objective (used as a LIFO stack).
    var commands: [Command] = []  // used as stack (LIFO via popLast)

    // MARK: - Methods

    /// Returns and removes the next order (LIFO).
    mutating func nextCommand() -> Command? {
        guard !commands.isEmpty else { return nil }
        return commands.removeLast()
    }
}
