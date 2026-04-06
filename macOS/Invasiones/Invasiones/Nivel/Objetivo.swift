// Nivel/Objetivo.swift
// Puerto de Objetivo.cs — representa un objetivo a cumplir (pila de órdenes).

import Foundation

class Objetivo {

    // MARK: - Declaraciones
    private var m_ordenes:    [Orden] = []  // used as stack (LIFO via popLast)
    private let m_pathImagen: String?

    // MARK: - Constructor
    init(pathImagen: String?) {
        m_pathImagen = pathImagen
    }

    // MARK: - Properties
    var ordenes: [Orden] {
        get { m_ordenes }
        set { m_ordenes = newValue }
    }

    // MARK: - Métodos

    /// Devuelve y elimina la próxima orden (LIFO).
    func proximaOrden() -> Orden? {
        guard !m_ordenes.isEmpty else { return nil }
        return m_ordenes.removeLast()
    }
}
