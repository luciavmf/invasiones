// Map/PathFinder/PathFinder.swift
// Puerto de PathFinder.cs — algoritmo A* para pathfinding en el mapa isométrico.

import Foundation

class PathFinder {

    // MARK: - Nodo interno

    private class Nodo: Equatable {
        var padre: Nodo?
        var costoG: Int = 0
        var costoH: Int = 0
        var costoF: Int = 0
        var i: Int
        var j: Int

        init(_ i: Int = 0, _ j: Int = 0) { self.i = i; self.j = j }

        static func == (a: Nodo, b: Nodo) -> Bool { a.i == b.i && a.j == b.j }
    }

    // MARK: - Constantes
    private let COSTO_DIAGONAL:  Int = 14
    private let COSTO_DERECHO:   Int = 10
    private let COSTO_IMPOSIBLE: Int = 99999
    private let TIMEOUT_SEG:     Double = 4.5  // equivalente a 45 décimas de segundo

    // MARK: - Singleton
    private static var m_instancia: PathFinder?

    static var Instancia: PathFinder {
        if m_instancia == nil { m_instancia = PathFinder() }
        return m_instancia!
    }

    // MARK: - Declaraciones
    private var m_mapaTilesFisicos: [[Int16]] = []
    private weak var m_mapa: Mapa?

    private init() {}

    // MARK: - Métodos

    func cargarMapa(_ mapa: Mapa) -> Bool {
        guard !mapa.capaTilesFisicos.isEmpty else { return false }
        m_mapaTilesFisicos = mapa.capaTilesFisicos
        m_mapa = mapa
        return true
    }

    /// Devuelve el camino más corto (pila de puntos i,j) o nil si no existe.
    func encontrarCaminoMasCorto(_ inicioI: Int, _ inicioJ: Int,
                                  _ objetivoI: Int, _ objetivoJ: Int) -> [(i: Int, j: Int)]? {
        guard let mapa = m_mapa, !m_mapaTilesFisicos.isEmpty else {
            Log.Instancia.advertir("PathFinder: mapa no cargado.")
            return nil
        }
        guard mapa.esPosicionCaminable(objetivoI, objetivoJ) else {
            Log.Instancia.debug("PathFinder: posición objetivo no caminable.")
            return nil
        }

        let inicio   = Nodo(inicioI, inicioJ)
        let objetivo = Nodo(objetivoI, objetivoJ)

        var abiertos:  [Nodo] = [inicio]
        var cerrados:  [Nodo] = []
        let startTime = Date()

        while !abiertos.isEmpty {
            if Date().timeIntervalSince(startTime) > TIMEOUT_SEG {
                Log.Instancia.debug("PathFinder: timeout.")
                return nil
            }

            guard let mejorIdx = abiertos.indices.min(by: { abiertos[$0].costoF < abiertos[$1].costoF }),
                  abiertos[mejorIdx].costoF < COSTO_IMPOSIBLE else { return nil }

            let mejor = abiertos.remove(at: mejorIdx)

            if mejor == objetivo {
                cerrados.append(mejor)
                return reconstruirCamino(desde: mejor, cerrados: cerrados)
            }

            agregarHijos(mejor, a: &abiertos, cerrados: cerrados, objetivo: objetivo, mapa: mapa)
            cerrados.append(mejor)
        }
        return nil
    }

    // MARK: - Helpers privados

    private func agregarHijos(_ padre: Nodo, a abiertos: inout [Nodo],
                               cerrados: [Nodo], objetivo: Nodo, mapa: Mapa) {
        let arr = abrirNodo(padre, padre.i - 1, padre.j,     COSTO_DERECHO,  &abiertos, cerrados, objetivo, mapa)
        let der = abrirNodo(padre, padre.i,     padre.j + 1, COSTO_DERECHO,  &abiertos, cerrados, objetivo, mapa)
        let abj = abrirNodo(padre, padre.i + 1, padre.j,     COSTO_DERECHO,  &abiertos, cerrados, objetivo, mapa)
        let izq = abrirNodo(padre, padre.i,     padre.j - 1, COSTO_DERECHO,  &abiertos, cerrados, objetivo, mapa)
        if arr && der { abrirNodo(padre, padre.i - 1, padre.j + 1, COSTO_DIAGONAL, &abiertos, cerrados, objetivo, mapa) }
        if der && abj { abrirNodo(padre, padre.i + 1, padre.j + 1, COSTO_DIAGONAL, &abiertos, cerrados, objetivo, mapa) }
        if abj && izq { abrirNodo(padre, padre.i + 1, padre.j - 1, COSTO_DIAGONAL, &abiertos, cerrados, objetivo, mapa) }
        if izq && arr { abrirNodo(padre, padre.i - 1, padre.j - 1, COSTO_DIAGONAL, &abiertos, cerrados, objetivo, mapa) }
    }

    @discardableResult
    private func abrirNodo(_ padre: Nodo, _ i: Int, _ j: Int, _ costo: Int,
                            _ abiertos: inout [Nodo], _ cerrados: [Nodo],
                            _ objetivo: Nodo, _ mapa: Mapa) -> Bool {
        guard mapa.esPosicionCaminable(i, j) else { return false }

        let hijo = Nodo(i, j)
        guard !cerrados.contains(hijo) else { return true }

        hijo.costoG = costo + padre.costoG
        hijo.costoH = (abs(i - objetivo.i) + abs(j - objetivo.j)) * COSTO_DERECHO
        hijo.costoF = hijo.costoG + hijo.costoH
        hijo.padre  = padre

        if !abiertos.contains(hijo) {
            abiertos.append(hijo)
        }
        return true
    }

    private func reconstruirCamino(desde nodo: Nodo, cerrados: [Nodo]) -> [(i: Int, j: Int)] {
        var camino: [(i: Int, j: Int)] = []
        var actual: Nodo? = nodo
        while let n = actual {
            camino.append((n.i, n.j))
            actual = n.padre
        }
        return camino // primer elemento = destino, último = origen
    }
}
