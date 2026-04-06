//
//  Objetivo.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Objetivo.cs — represents an objective to fulfill (stack of orders).
//

import Foundation

class Objetivo {

    // MARK: - Declarations
    private var m_ordenes:    [Orden] = []  // used as stack (LIFO via popLast)
    private let m_pathImagen: String?

    // MARK: - Initializer
    init(pathImagen: String?) {
        m_pathImagen = pathImagen
    }

    // MARK: - Properties
    var ordenes: [Orden] {
        get { m_ordenes }
        set { m_ordenes = newValue }
    }

    // MARK: - Methods

    /// Returns and removes the next order (LIFO).
    func proximaOrden() -> Orden? {
        guard !m_ordenes.isEmpty else { return nil }
        return m_ordenes.removeLast()
    }
}
