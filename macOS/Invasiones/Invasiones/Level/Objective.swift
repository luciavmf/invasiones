//
//  Objective.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Objetivo.cs — represents an objective to fulfill (stack of orders).
//

import Foundation

class Objective {

    // MARK: - Declarations
    var commands: [Command] = []  // used as stack (LIFO via popLast)
    private let imagePath: String?

    // MARK: - Initializer
    init(pathImagen: String?) {
        imagePath = pathImagen
    }

    // MARK: - Methods

    /// Returns and removes the next order (LIFO).
    func nextCommand() -> Command? {
        guard !commands.isEmpty else { return nil }
        return commands.removeLast()
    }
}
