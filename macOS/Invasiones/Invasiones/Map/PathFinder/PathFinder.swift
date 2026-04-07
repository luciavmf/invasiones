//
//  PathFinder.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of PathFinder.cs — A* pathfinding algorithm for the isometric map.
//

import Foundation

class PathFinder {

    // MARK: - Internal node

    private class Node: Equatable {
        var parent: Node?
        var costG: Int = 0
        var costH: Int = 0
        var costF: Int = 0
        var i: Int
        var j: Int

        init(_ i: Int = 0, _ j: Int = 0) { self.i = i; self.j = j }

        static func == (a: Node, b: Node) -> Bool { a.i == b.i && a.j == b.j }
    }

    // MARK: - Constants
    private let COST_DIAGONAL:  Int = 14
    private let COST_STRAIGHT:  Int = 10
    private let COST_IMPOSSIBLE: Int = 99999
    private let TIMEOUT_SECS:   Double = 4.5

    // MARK: - Singleton

    static let shared: PathFinder = PathFinder()

    // MARK: - Declarations
    private var physicalTiles: [[Int]] = []
    private weak var map: Map?

    private init() { }

    // MARK: - Methods

    func loadMap(_ map: Map) throws {
        guard !map.physicalTilesLayer.isEmpty else {
            throw GameError.invalidResource("PathFinder: el mapa no tiene capa física.")
        }
        physicalTiles = map.physicalTilesLayer
        self.map = map
    }

    /// Returns the shortest path (stack of (i,j) points) or nil if none exists.
    func findShortestPath(startI: Int, startJ: Int,
                         targetI: Int, targetJ: Int) -> [(i: Int, j: Int)]? {
        guard let map = self.map, !physicalTiles.isEmpty else {
            Log.shared.warn("PathFinder: map not loaded.")
            return nil
        }
        guard map.isWalkable(x: targetI, y: targetJ) else {
            Log.shared.debug("PathFinder: target position not walkable.")
            return nil
        }

        let start = Node(startI, startJ)
        let target = Node(targetI, targetJ)

        var open:   [Node] = [start]
        var closed: [Node] = []
        let startTime = Date()

        while !open.isEmpty {
            if Date().timeIntervalSince(startTime) > TIMEOUT_SECS {
                Log.shared.debug("PathFinder: timeout.")
                return nil
            }

            guard let bestIdx = open.indices.min(by: { open[$0].costF < open[$1].costF }),
                  open[bestIdx].costF < COST_IMPOSSIBLE else { return nil }

            let best = open.remove(at: bestIdx)

            if best == target {
                closed.append(best)
                return reconstructPath(from: best, closed: closed)
            }

            addChildren(parent: best, open: &open, closed: closed, target: target, map: map)
            closed.append(best)
        }
        return nil
    }

    // MARK: - Private helpers

    private func addChildren(parent: Node, open: inout [Node],
                             closed: [Node], target: Node, map: Map) {
        let up = openNode(parent: parent, i: parent.i - 1, j: parent.j, cost: COST_STRAIGHT, open: &open, closed: closed, target: target, map: map)
        let right = openNode(parent: parent, i: parent.i, j: parent.j + 1, cost: COST_STRAIGHT, open: &open, closed: closed, target: target, map: map)
        let down = openNode(parent: parent, i: parent.i + 1, j: parent.j, cost: COST_STRAIGHT, open: &open, closed: closed, target: target, map: map)
        let left = openNode(parent: parent, i: parent.i, j: parent.j - 1, cost: COST_STRAIGHT, open: &open, closed: closed, target: target, map: map)
        if up    && right { openNode(parent: parent, i: parent.i - 1, j: parent.j + 1, cost: COST_DIAGONAL, open: &open, closed: closed, target: target, map: map) }
        if right && down  { openNode(parent: parent, i: parent.i + 1, j: parent.j + 1, cost: COST_DIAGONAL, open: &open, closed: closed, target: target, map: map) }
        if down  && left  { openNode(parent: parent, i: parent.i + 1, j: parent.j - 1, cost: COST_DIAGONAL, open: &open, closed: closed, target: target, map: map) }
        if left  && up    { openNode(parent: parent, i: parent.i - 1, j: parent.j - 1, cost: COST_DIAGONAL, open: &open, closed: closed, target: target, map: map) }
    }

    @discardableResult
    private func openNode(parent: Node, i: Int, j: Int, cost: Int,
                          open: inout [Node], closed: [Node],
                          target: Node, map: Map) -> Bool {
        guard map.isWalkable(x: i, y: j) else { return false }

        let child = Node(i, j)
        guard !closed.contains(child) else { return true }

        child.costG = cost + parent.costG
        child.costH = (abs(i - target.i) + abs(j - target.j)) * COST_STRAIGHT
        child.costF = child.costG + child.costH
        child.parent = parent

        if !open.contains(child) {
            open.append(child)
        }
        return true
    }

    private func reconstructPath(from node: Node, closed: [Node]) -> [(i: Int, j: Int)] {
        var path: [(i: Int, j: Int)] = []
        var current: Node? = node
        while let n = current {
            path.append((n.i, n.j))
            current = n.parent
        }
        return path // first element = destination, last = origin
    }
}
