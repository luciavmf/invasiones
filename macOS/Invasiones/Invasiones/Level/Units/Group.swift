//
//  Group.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Grupo.cs — collection of units sharing a movement strategy.
//

import Foundation

class Group {

    // MARK: - Constants
    static let UNIT_SPACING = 2
    static let MAX_DISTANCE = 99999
    private static var s_random: Bool = true  // initialized once

    enum State {
        case waitingCommand, grouping, moving, healing, attacking, eliminating, pursuingEnemy
    }

    // MARK: - Statics
    static var map: Map?

    // MARK: - Attributes
    var ai: IA?
    private var nextStateValue: State = .waitingCommand
    private var objectiveCommand: Command?
    private var targetTile: (x: Int, y: Int) = (0, 0)
    private var receivedCommand: Command?
    private var completedOrder: Bool = false
    private var stateValue: State = .waitingCommand
    var units: [Unit] = []
    private var speed: Int = 100
    var isSelected: Bool = false {
        didSet { units.forEach { $0.isSelected = isSelected } }
    }
    private var commander: Unit?
    private var avgHealth: Int = 0
    private var avgResistance: Int = 0
    private let groupId: Int

    // MARK: - Properties
    var health: Int { avgHealth }
    var resistancePoints: Int { avgResistance }
    var currentState: State { stateValue }
    var soldierCount: Int { units.count }
    var maxSpeed: Int {
        get { speed }
        set { speed = newValue }
    }
    var id: Int { groupId }

    // MARK: - Initializer
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
        case .waitingCommand:   updateWaitingState()
        case .moving:          updateMovingState()
        case .grouping:         updateGroupingState()
        case .pursuingEnemy: break
        case .attacking:         break
        case .healing:           updateHealingState()
        case .eliminating:         return
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

    func move(x: Int, y: Int) {
        receivedCommand = Command(.MOVE, x, y)
        setState(.grouping)
        targetTile = (x, y)

        if commander == nil { setCommander() }
        nextStateValue = .waitingCommand

        moveUnitsToFormation()
    }

    func attack(enemy: Unit) {
        units.forEach { $0.attack(enemy) }
    }

    func heal(x: Int, y: Int) {
        receivedCommand = Command(.HEAL, x, y)
        if commander == nil { setAuxCommander() }

        guard let map = Group.map, let cmd = commander else { return }
        let p = map.getLineOfSightPosition(
            x, cmd.physicalTilePos.x,
            y, cmd.physicalTilePos.y)
        if p.x == -1 {
            Log.shared.debug("Group: No se puede mandar a heal.")
            return
        }
        setHealing(x: p.x, y: p.y)
    }

    func setAI(_ intel: IA) {
        ai = intel
        setState(.waitingCommand)
    }

    func dissolve() {
        units.forEach { $0.leaveGroup() }
    }

    func removeUnit(_ unit: Unit) {
        units.removeAll { $0 === unit }
        if unit === commander {
            commander = nil
            unit.unmarkCommander()
            setAuxCommander()
        }
        if units.count <= 1 { setState(.eliminating) }
    }

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
        receivedCommand = Command(.HEAL, x, y)
        nextStateValue = .healing
    }

    private func updateWaitingState() {
        guard let ia = ai else { return }
        if receivedCommand == nil {
            receivedCommand = ia.nextCommand()
        }
        if let ord = receivedCommand, ord.id == .MOVE {
            setObjectiveCommand(.MOVE, ord.point.x, ord.point.y)
            move(x: ord.point.x, y: ord.point.y)
        }
    }

    private func updateGroupingState() {
        let allIdle = units.allSatisfy { $0.currentState == .IDLE }
        guard allIdle else { return }

        guard let ord = receivedCommand,
              ord.id == .MOVE || ord.id == .HEAL else { return }

        commander?.move(targetTile.x, targetTile.y)
        if commander?.pathToFollow == nil {
            setState(.waitingCommand)
            return
        }

        setState(.moving)

        if let path = commander?.pathToFollow {
            for unit in units {
                unit.calculatePathAtDistance(path,
                                               unit.formationOffset.x,
                                               unit.formationOffset.y)
            }
        }
    }

    private func updateMovingState() {
        let isHealOrder = receivedCommand?.id == .HEAL
        let allIdle = units.allSatisfy {
            $0.currentState == .IDLE || (isHealOrder && $0.currentState == .HEALING)
        }

        if isHealOrder {
            for unit in units where unit.currentState == .IDLE {
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
            if ord.id == .MOVE, unit.completedMoveObjective() {
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
                if map.isWalkable(x + i, y + j) {
                    units[index].formationOffset = (i, j)
                    units[index].move(x + i, y + j)
                    units[index].setObjectiveCommand(objectiveCommand)
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
            case 1:  // UP
                i += 2; if i == inc { dir = 2 }
            case 2:  // RIGHT
                j += 2; if j == inc { dir = 3 }
            case 3:  // DOWN
                i -= 2; if i == -inc { dir = 0 }
            case 0:  // LEFT
                j -= 2; if j == -inc { dir = 1; inc += 2 }
            default: break
            }
        }
    }

    private func setObjectiveCommand(_ type: Command.TYPE, _ x: Int, _ y: Int) {
        objectiveCommand = Command(type, x, y)
    }
}
