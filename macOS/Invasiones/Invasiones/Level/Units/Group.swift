//
//  Group.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Grupo.cs — collection of units sharing a movement strategy.
//

import Foundation

/// A collection of units grouped by the player for convenience.
/// Each unit maintains its unique position relative to the group leader (formation offset).
/// The group coordinates movement using a spiral formation algorithm and delegates attack/heal orders to individual units.
class Group {

    private static var s_random: Bool = true  // initialized once

    enum State {
        case waitingCommand, grouping, moving, healing, attacking, eliminating, pursuingEnemy
    }

    // MARK: - Statics
    /// The map shared by all groups (used for pathfinding and walkability checks).
    static var map: Map?

    // MARK: - Attributes
    /// The AI controller that provides scripted orders for enemy groups.
    var ai: IA?
    /// The next state the group will enter after the current movement completes.
    private var nextStateValue: State = .waitingCommand
    /// The command passed down to individual units as the group's objective.
    private var objectiveCommand: Command?
    /// The tile the group leader is heading toward.
    private var targetTile: (x: Int, y: Int) = (0, 0)
    /// The most recent command the group received.
    private var receivedCommand: Command?
    private var completedOrder: Bool = false
    private var stateValue: State = .waitingCommand
    var units: [Unit] = []
    /// The maximum movement speed of the group (limited to the slowest unit).
    private var speed: Int = 100
    /// Whether the group is selected. Setting this propagates selection to all member units.
    var isSelected: Bool = false {
        didSet { units.forEach { $0.isSelected = isSelected } }
    }
    /// The commander unit whose path determines the group's movement route.
    private var commander: Unit?
    /// Average health across all units in the group.
    private var avgHealth: Int = 0
    /// Average resistance points across all units in the group.
    private var avgResistance: Int = 0
    private let groupId: Int

    // MARK: - Properties
    /// Average health of all units in the group.
    var health: Int { avgHealth }
    /// Average maximum health (resistance points) of all units in the group.
    var resistancePoints: Int { avgResistance }
    var currentState: State { stateValue }
    /// The number of soldiers currently in the group.
    var soldierCount: Int { units.count }
    var maxSpeed: Int {
        get { speed }
        set { speed = newValue }
    }
    var id: Int { groupId }

    // MARK: - Initializer
    /// Creates a new group from the provided list of units.
    /// - Parameter units: The units to include in the group.
    init(_ units: [Unit]) {
        groupId = Int.random(in: 0...99999)
        self.units = units
        speed = 100
        avgResistance = 0

        for unit in units {
            unit.joinGroup(self)
            if unit.speed.x < speed {
                speed = unit.speed.x
            }
            avgResistance += unit.resistancePoints
        }
        if !units.isEmpty {
            avgResistance /= units.count
        }
    }

    // MARK: - Update

    func update() {
        switch stateValue {
        case .waitingCommand: updateWaitingState()
        case .moving: updateMovingState()
        case .grouping: updateGroupingState()
        case .pursuingEnemy: break
        case .attacking: break
        case .healing: updateHealingState()
        case .eliminating: return
        }

        checkHealthAndOrder()
        removeDeadUnits()

        if units.count <= 1 {
            setState(.eliminating)
        }

        if let cmd = commander, cmd.isDead() {
            setAuxCommander()
        }
    }

    // MARK: - Public orders

    /// Orders the group to move to tile (x, y), entering the formation-grouping phase first.
    func move(x: Int, y: Int) {
        receivedCommand = Command(.move, x, y)
        setState(.grouping)
        targetTile = (x, y)

        if commander == nil { setCommander() }
        nextStateValue = .waitingCommand

        moveUnitsToFormation()
    }

    /// Orders all units in the group to attack the given enemy unit.
    func attack(enemy: Unit) {
        units.forEach { $0.attack(enemy: enemy) }
    }

    /// Orders the group to move to the nearest walkable tile near (x, y) and then heal.
    func heal(x: Int, y: Int) {
        receivedCommand = Command(.heal, x, y)
        if commander == nil { setAuxCommander() }

        guard let map = Group.map, let cmd = commander else { return }
        let p = map.getLineOfSightPosition(
            x1: x, x2: cmd.physicalTilePos.x,
            y1: y, y2: cmd.physicalTilePos.y)
        if p.x == -1 {
            Log.shared.debug("Group: no heal location found.")
            return
        }
        setHealing(x: p.x, y: p.y)
    }

    /// Assigns an AI controller to this group and puts it into the waiting-for-order state.
    func setAI(_ intel: IA) {
        ai = intel
        setState(.waitingCommand)
    }

    /// Dissolves the group, releasing all member units back to individual control.
    func dissolve() {
        units.forEach { $0.leaveGroup() }
    }

    /// Removes a single unit from the group, reassigning the commander if necessary.
    func removeUnit(_ unit: Unit) {
        units.removeAll { $0 === unit }
        if unit === commander {
            commander = nil
            unit.unmarkCommander()
            setAuxCommander()
        }
        if units.count <= 1 { setState(.eliminating) }
    }

    /// Returns the sole remaining unit when the group has been reduced to one member, or `nil` otherwise.
    func getLastUnit() -> Unit? {
        units.count == 1 ? units[0] : nil
    }

    // MARK: - Private

    private func setState(_ state: State) {
        stateValue = state
        if state == .waitingCommand {
            completedOrder = false
            receivedCommand = nil
        }
    }

    private func setCommander() {
        guard !units.isEmpty else { return }
        commander = units[0]
        commander?.markAsCommander()
    }

    private func setAuxCommander() {
        guard units.count >= 2 else { return }
        commander = units[0]
        commander?.markAsCommander()
    }

    private func setHealing(x: Int, y: Int) {
        move(x: x, y: y)
        receivedCommand = Command(.heal, x, y)
        nextStateValue = .healing
    }

    private func updateWaitingState() {
        guard let ia = ai else { return }
        if receivedCommand == nil {
            receivedCommand = ia.nextCommand()
        }
        if let ord = receivedCommand, ord.id == .move {
            setObjectiveCommand(type: .move, x: ord.point.x, y: ord.point.y)
            move(x: ord.point.x, y: ord.point.y)
        }
    }

    private func updateGroupingState() {
        let allIdle = units.allSatisfy { $0.currentState == .idle }
        guard allIdle else { return }

        guard let ord = receivedCommand,
              ord.id == .move || ord.id == .heal else { return }

        commander?.move(x: targetTile.x, y: targetTile.y)
        if commander?.pathToFollow == nil {
            setState(.waitingCommand)
            return
        }

        setState(.moving)

        if let path = commander?.pathToFollow {
            for unit in units {
                unit.calculatePathAtDistance(commanderPath: path,
                                             offsetX: unit.formationOffset.x,
                                             offsetY: unit.formationOffset.y)
            }
        }
    }

    private func updateMovingState() {
        let isHealOrder = receivedCommand?.id == .heal
        let allIdle = units.allSatisfy {
            $0.currentState == .idle || (isHealOrder && $0.currentState == .healing)
        }

        if isHealOrder {
            for unit in units where unit.currentState == .idle {
                if unit.health != unit.resistancePoints {
                    unit.recoverHealth()
                }
            }
        }

        if allIdle {
            setState(nextStateValue)
        }
    }

    private func updateHealingState() {
        let allHealed = units.allSatisfy { $0.health == $0.resistancePoints }
        if allHealed {
            setState(.waitingCommand)
        }
    }

    private func checkHealthAndOrder() {
        guard let ord = receivedCommand else { return }

        avgHealth = 0
        for unit in units {
            avgHealth += unit.health
            if ord.id == .move, unit.completedMoveObjective() {
                completedOrder = true
            }
        }
        if !units.isEmpty {
            avgHealth /= units.count
            if completedOrder {
                setState(.waitingCommand)
            }
        } else {
            avgHealth = 0
        }
    }

    private func removeDeadUnits() {
        let dead = units.filter { $0.isDead() }
        guard !dead.isEmpty else { return }

        units.removeAll { $0.isDead() }
        avgResistance = 0
        if !units.isEmpty {
            avgResistance = units.reduce(0) { $0 + $1.resistancePoints } / units.count
        }
    }

    private func moveUnitsToFormation() {
        guard let cmd = commander else { return }
        let x = cmd.physicalTilePos.x
        let y = cmd.physicalTilePos.y
        guard let map = Group.map else { return }

        var i = 0, j = 0, inc = 2
        var dir = 1  // UP
        var placed = 1
        var index = 0

        cmd.formationOffset = (0, 0)

        // C# parity: index only advances when a unit is actually placed OR is the commander.
        // If the spiral position is non-walkable for a non-commander unit, we advance the spiral
        // but keep the same unit index so it is retried at the next walkable position.
        while placed < units.count && index < units.count {
            if units[index] !== cmd {
                if map.isWalkable(x: x + i, y: y + j) {
                    units[index].formationOffset = (i, j)
                    units[index].move(x: x + i, y: y + j)
                    units[index].setObjectiveCommand(ord: objectiveCommand)
                    placed += 1
                    index += 1  // only advance when placed
                }
                // else: non-walkable, keep same index and try next spiral position
            } else {
                cmd.stop()
                index += 1
            }

            // spiral
            switch dir {
            case 1: // UP
                i += 2
                if i == inc { dir = 2 }
            case 2: // RIGHT
                j += 2
                if j == inc { dir = 3 }
            case 3: // DOWN
                i -= 2
                if i == -inc { dir = 0 }
            case 0: // LEFT
                j -= 2
                if j == -inc {
                    dir = 1
                    inc += 2
                }
            default: break
            }
        }
    }

    private func setObjectiveCommand(type: Command.Kind, x: Int, y: Int) {
        objectiveCommand = Command(type, x, y)
    }
}
