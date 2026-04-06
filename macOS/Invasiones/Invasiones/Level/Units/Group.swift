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

    enum STATE {
        case WAITING_FOR_ORDER, GROUPING, MOVING, HEALING, ATTACKING, ELIMINATED, PURSUING_ENEMY
    }

    // MARK: - Statics
    static var map: Map?

    // MARK: - Attributes
    var m_ai:         IA?
    private var m_nextState:     STATE = .WAITING_FOR_ORDER
    private var m_objectiveCommand:     Command?
    private var m_targetTile:      (x: Int, y: Int) = (0, 0)
    private var m_receivedCommand:     Command?
    private var m_completedOrder:      Bool = false
    private var m_state:            STATE = .WAITING_FOR_ORDER
    private var m_units:          [Unit] = []
    private var m_speed:         Int = 100
    private var m_isSelected:    Bool = false
    private var m_commander:        Unit?
    private var m_avgHealth:     Int = 0
    private var m_avgResistance: Int = 0
    private let m_groupId:           Int

    // MARK: - Properties
    var health:              Int { m_avgHealth }
    var resistancePoints:Int { m_avgResistance }
    var currentState:       STATE { m_state }
    var units:           [Unit] {
        get { m_units }
        set { m_units = newValue }
    }
    var soldierCount: Int { m_units.count }
    var maxSpeed:    Int {
        get { m_speed }
        set { m_speed = newValue }
    }
    var id: Int { m_groupId }

    var isSelected: Bool {
        get { m_isSelected }
        set {
            m_units.forEach { $0.isSelected = newValue }
            m_isSelected = newValue
        }
    }

    // MARK: - Initializer
    init(_ units: [Unit]) {
        m_groupId  = Int.random(in: 0...99999)
        m_units = units
        m_speed = 100
        m_avgResistance = 0

        for unit in units {
            unit.joinGroup(self)
            if unit.speed.x < m_speed {
                m_speed = unit.speed.x
            }
            m_avgResistance += unit.resistancePoints
        }
        if !m_units.isEmpty {
            m_avgResistance /= m_units.count
        }
    }

    // MARK: - Update

    func update() {
        switch m_state {
        case .WAITING_FOR_ORDER:   updateWaitingState()
        case .MOVING:          updateMovingState()
        case .GROUPING:         updateGroupingState()
        case .PURSUING_ENEMY: break
        case .ATTACKING:         break
        case .HEALING:           updateHealingState()
        case .ELIMINATED:         return
        }

        checkHealthAndOrder()
        removeDeadUnits()

        if m_units.count <= 1 {
            setState(.ELIMINATED)
        }

        if let cmd = m_commander, cmd.isDead() {
            setAuxCommander()
        }
    }

    // MARK: - Public orders

    func move(_ x: Int, _ y: Int) {
        m_receivedCommand = Command(.MOVE, x, y)
        setState(.GROUPING)
        m_targetTile  = (x, y)

        if m_commander == nil { setCommander() }
        m_nextState = .WAITING_FOR_ORDER

        moveUnitsToFormation()
    }

    func attack(_ enemy: Unit) {
        m_units.forEach { $0.attack(enemy) }
    }

    func heal(_ x: Int, _ y: Int) {
        m_receivedCommand = Command(.HEAL, x, y)
        if m_commander == nil { setAuxCommander() }

        guard let map = Group.map, let cmd = m_commander else { return }
        let p = map.getLineOfSightPosition(
            x, cmd.physicalTilePos.x,
            y, cmd.physicalTilePos.y)
        if p.x == -1 {
            Log.shared.debug("Group: No se puede mandar a heal.")
            return
        }
        setHealing(p.x, p.y)
    }

    func setAI(_ intel: IA) {
        m_ai = intel
        setState(.WAITING_FOR_ORDER)
    }

    func dissolve() {
        m_units.forEach { $0.leaveGroup() }
    }

    func removeUnit(_ unit: Unit) {
        m_units.removeAll { $0 === unit }
        if unit === m_commander {
            m_commander = nil
            unit.unmarkCommander()
            setAuxCommander()
        }
        if m_units.count <= 1 { setState(.ELIMINATED) }
    }

    func getLastUnit() -> Unit? {
        m_units.count == 1 ? m_units[0] : nil
    }

    // MARK: - Private

    private func setState(_ state: STATE) {
        m_state = state
        if state == .WAITING_FOR_ORDER {
            m_completedOrder  = false
            m_receivedCommand = nil
        }
    }

    private func setCommander() {
        guard !m_units.isEmpty else { return }
        m_commander = m_units[0]
        m_commander?.markAsCommander()
    }

    private func setAuxCommander() {
        guard m_units.count >= 2 else { return }
        m_commander = m_units[0]
        m_commander?.markAsCommander()
    }

    private func setHealing(_ x: Int, _ y: Int) {
        move(x, y)
        m_receivedCommand = Command(.HEAL, x, y)
        m_nextState = .HEALING
    }

    private func updateWaitingState() {
        guard let ia = m_ai else { return }
        if m_receivedCommand == nil {
            m_receivedCommand = ia.nextCommand()
        }
        if let ord = m_receivedCommand, ord.id == .MOVE {
            setObjectiveCommand(.MOVE, ord.point.x, ord.point.y)
            move(ord.point.x, ord.point.y)
        }
    }

    private func updateGroupingState() {
        let allIdle = m_units.allSatisfy { $0.currentState == .IDLE }
        guard allIdle else { return }

        guard let ord = m_receivedCommand,
              ord.id == .MOVE || ord.id == .HEAL else { return }

        m_commander?.move(m_targetTile.x, m_targetTile.y)
        if m_commander?.pathToFollow == nil {
            setState(.WAITING_FOR_ORDER)
            return
        }

        setState(.MOVING)

        if let path = m_commander?.pathToFollow {
            for unit in m_units {
                unit.calculatePathAtDistance(path,
                                               unit.formationOffset.x,
                                               unit.formationOffset.y)
            }
        }
    }

    private func updateMovingState() {
        let isHealOrder = m_receivedCommand?.id == .HEAL
        let allIdle = m_units.allSatisfy {
            $0.currentState == .IDLE || (isHealOrder && $0.currentState == .HEALING)
        }

        if isHealOrder {
            for unit in m_units where unit.currentState == .IDLE {
                if unit.health != unit.resistancePoints {
                    unit.recoverHealth()
                }
            }
        }

        if allIdle {
            setState(m_nextState)
        }
    }

    private func updateHealingState() {
        let allHealed = m_units.allSatisfy { $0.health == $0.resistancePoints }
        if allHealed {
            setState(.WAITING_FOR_ORDER)
        }
    }

    private func checkHealthAndOrder() {
        guard let ord = m_receivedCommand else { return }

        m_avgHealth = 0
        for unit in m_units {
            m_avgHealth += unit.health
            if ord.id == .MOVE, unit.completedMoveObjective() {
                m_completedOrder = true
            }
        }
        if !m_units.isEmpty {
            m_avgHealth /= m_units.count
            if m_completedOrder {
                setState(.WAITING_FOR_ORDER)
            }
        } else {
            m_avgHealth = 0
        }
    }

    private func removeDeadUnits() {
        let dead = m_units.filter { $0.isDead() }
        guard !dead.isEmpty else { return }

        m_units.removeAll { $0.isDead() }
        m_avgResistance = 0
        if !m_units.isEmpty {
            m_avgResistance = m_units.reduce(0) { $0 + $1.resistancePoints } / m_units.count
        }
    }

    private func moveUnitsToFormation() {
        guard let cmd = m_commander else { return }
        let x = cmd.physicalTilePos.x
        let y = cmd.physicalTilePos.y
        guard let map = Group.map else { return }

        var i = 0, j = 0, inc = 2
        var dir = 1  // UP
        var placed = 1
        var index  = 0

        cmd.formationOffset = (0, 0)

        // C# parity: index only advances when a unit is actually placed OR is the commander.
        // If the spiral position is non-walkable for a non-commander unit, we advance the spiral
        // but keep the same unit index so it is retried at the next walkable position.
        while placed < m_units.count && index < m_units.count {
            if m_units[index] !== cmd {
                if map.isWalkable(x + i, y + j) {
                    m_units[index].formationOffset = (i, j)
                    m_units[index].move(x + i, y + j)
                    m_units[index].setObjectiveCommand(m_objectiveCommand)
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
        m_objectiveCommand = Command(type, x, y)
    }
}
