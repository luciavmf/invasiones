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
    private var m_commands:    [Command] = []  // used as stack (LIFO via popLast)
    private let m_imagePath: String?

    // MARK: - Initializer
    init(pathImagen: String?) {
        m_imagePath = pathImagen
    }

    // MARK: - Properties
    var commands: [Command] {
        get { m_commands }
        set { m_commands = newValue }
    }

    // MARK: - Methods

    /// Returns and removes the next order (LIFO).
    func nextCommand() -> Command? {
        guard !m_commands.isEmpty else { return nil }
        return m_commands.removeLast()
    }
}
