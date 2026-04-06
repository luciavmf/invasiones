//
//  Player.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Jugador.cs — abstract base class for both game factions.
//

import Foundation

class Player {

    // MARK: - Enums
    enum STATE { case START, LOADING, GAME }

    // MARK: - Protected attributes
    var m_completedObjective:         Bool = false
    var m_faction:                   Episode.BANDO = .ARGENTINE
    var m_someoneCompletedOrder:   Bool = false
    var m_ring:                     AnimObject?

    var m_hud:                     Hud
    var m_units:                [Unit] = []
    var m_objectsToDraw:          ObjectTable     // [physicalMapHeight][physicalMapWidth]
    var m_map:                    Map
    var m_groups:                  [Group]? = nil
    var m_state:                  STATE = .START
    var m_camera:                  Camera
    var m_selectedUnits:   [Unit] = []
    var m_deadUnits:         [Unit]? = nil
    var m_visibleUnits:        [Unit]? = nil
    var m_collidingUnits:   [Unit]? = nil
    var m_selectedUnit:      Unit?
    var m_selectedGroup:       Group?
    var m_objective:                Objective?
    var m_command:                   Command?
    var m_objectToTake:            MapObject?
    var m_fireEffects:               [AnimObject]? = nil

    var unitCount: Int { m_units.count }

    // MARK: - Initializer
    init(map: Map, camera: Camera, objectsToDraw: ObjectTable, hud: Hud) {
        m_map = map
        m_camera = camera
        m_objectsToDraw = objectsToDraw
        m_hud           = hud
    }

    // MARK: - Abstract methods (deben ser sobreescritos)
    func update() { fatalError("update() must be overridden") }
    func loadUnits(_ levelIndex: Int) -> Bool { fatalError("loadUnits must be overridden") }

    // MARK: - Objective completion
    func completedObjective() -> Bool { m_completedObjective }

    // MARK: - Set objective
    func setObjective(_ objective: Objective?) {
        m_objective        = objective
        m_completedObjective = false

        if let obj = objective {
            m_command = obj.nextCommand()

            if let ord = m_command {
                if ord.id == .TAKE_OBJECT, let img = ord.image {
                    m_objectToTake = MapObject(sup: img, i: ord.point.x, j: ord.point.y)
                }
                m_ring?.setPosition(ord.point.x, ord.point.y)
            }
        } else {
            m_command = nil
        }

        m_units.forEach { $0.setObjectiveCommand(m_command) }
    }

    func setNextCommand() {
        m_someoneCompletedOrder = false
        m_command = m_objective?.nextCommand()

        if m_command == nil {
            m_completedObjective = true
        } else {
            // Automatically process TRIGGERs
            while let ord = m_command, ord.id == .TRIGGER {
                if m_fireEffects == nil { m_fireEffects = [] }
                if let anim = ord.animation {
                    m_fireEffects!.append(anim)
                    m_map.invalidateTile(ord.point.x, ord.point.y)

                    let anim2 = AnimObject(Animation(copia: anim.animation),
                                          ord.animation!.physicalTilePos.x - 5,
                                          ord.animation!.physicalTilePos.y - 5)
                    m_fireEffects!.append(anim2)
                    m_map.invalidateTile(anim.physicalTilePos.x - 5, anim.physicalTilePos.y - 5)

                    let anim3 = AnimObject(Animation(copia: anim.animation),
                                          ord.animation!.physicalTilePos.x - 5,
                                          ord.animation!.physicalTilePos.y)
                    m_fireEffects!.append(anim3)
                    m_map.invalidateTile(anim.physicalTilePos.x - 5, anim.physicalTilePos.y)
                }
                m_command = m_objective?.nextCommand()
                if m_command == nil { m_completedObjective = true }
            }
            if let ord = m_command {
                m_ring?.setPosition(ord.point.x, ord.point.y)
            }
        }

        m_units.forEach { $0.setObjectiveCommand(m_command) }
    }

    // MARK: - Unit update (shared)

    func updateUnits() {
        m_deadUnits = nil
        let checkSelection = m_selectedUnit == nil && m_selectedGroup == nil

        for unit in m_units {
            updateAndMoveUnitInObjectMap(unit)

            if checkSelection, unit.isSelected {
                if m_selectedUnits.count < 6 {
                    m_hud.selectedUnit = unit
                    m_selectedUnits.append(unit)
                } else {
                    unit.isSelected = false
                }
            }

            m_visibleUnits = getVisibleUnitsAndTiles(unit)

            if unit.isMoving() {
                checkCollisions(unit)
            }

            if unit.currentState == .IDLE || unit.currentState == .PATROLLING {
                attackVisibleUnits(unit)
            }

            if unit.currentState == .DEAD {
                if m_deadUnits == nil { m_deadUnits = [] }
                m_deadUnits!.append(unit)
            }

            if unit.completedOrder { m_someoneCompletedOrder = true }
        }

        // Check KILL order
        if let ord = m_command, ord.id == .KILL {
            m_someoneCompletedOrder = true
            let iStart = ord.point.x - ord.width
            let iEnd   = ord.point.x + ord.width
            let jStart = ord.point.y - ord.width
            let jEnd   = ord.point.y + ord.width

            for i in iStart..<iEnd {
                for j in jStart..<jEnd {
                    guard i >= 0, j >= 0, i < m_objectsToDraw.tabla.count,
                          j < m_objectsToDraw.tabla[i].count else { continue }
                    if let u = m_objectsToDraw.tabla[i][j] as? Unit, u.faction == .ENEMY {
                        m_someoneCompletedOrder = false
                    }
                }
            }
        }
    }

    func removeDeadUnits() {
        guard let muertas = m_deadUnits else { return }
        for dead in muertas {
            let ti = dead.physicalTilePos.x
            let tj = dead.physicalTilePos.y
            if ti < m_objectsToDraw.tabla.count, tj < m_objectsToDraw.tabla[ti].count {
                m_objectsToDraw.tabla[ti][tj] = nil
            }
            m_units.removeAll { $0 === dead }
        }
    }

    // MARK: - Private

    private func updateAndMoveUnitInObjectMap(_ unit: Unit) {
        let moved = unit.update()
        if moved {
            let prevI = unit.previousTile.x
            let prevJ = unit.previousTile.y
            if prevI < m_objectsToDraw.tabla.count, prevJ < m_objectsToDraw.tabla[prevI].count {
                if m_objectsToDraw.tabla[prevI][prevJ] === unit {
                    m_objectsToDraw.tabla[prevI][prevJ] = nil
                }
            }
            let ni = unit.physicalTilePos.x
            let nj = unit.physicalTilePos.y
            if ni < m_objectsToDraw.tabla.count, nj < m_objectsToDraw.tabla[ni].count {
                m_objectsToDraw.tabla[ni][nj] = unit
            }
        }
    }

    private func checkCollisions(_ unit: Unit) {
        m_collidingUnits = getUnitsToCollide(unit)
        for other in (m_collidingUnits ?? []) {
            if unit.hasCollision(other) {
                unit.evadeUnit(other, m_visibleUnits)
            }
        }
    }

    func getVisibleUnitsAndTiles(_ unit: Unit) -> [Unit]? {
        var visible: [Unit]? = nil
        let iStart = max(0, unit.physicalTilePos.x - Unit.MAX_VISIBILITY)
        let jStart = max(0, unit.physicalTilePos.y - Unit.MAX_VISIBILITY)
        let iFin    = min(m_map.physicalMapHeight,  unit.physicalTilePos.x + Unit.MAX_VISIBILITY)
        let jFin    = min(m_map.physicalMapWidth, unit.physicalTilePos.y + Unit.MAX_VISIBILITY)
        let esVisible = unit.isOnScreen()

        for i in iStart..<iFin {
            for j in jStart..<jFin {
                let dist = unit.calculateDistance(i, j)
                guard dist <= Double(unit.visibility) else { continue }

                if i < m_objectsToDraw.tabla.count, j < m_objectsToDraw.tabla[i].count,
                   let other = m_objectsToDraw.tabla[i][j] as? Unit, other !== unit {
                    if visible == nil { visible = [] }
                    visible!.append(other)
                }

                if esVisible && unit.faction == .ARGENTINE {
                    m_map.visibleTilesLayer[i][j] = Int16(Map.TILE_VISIBLE)
                }
            }
        }
        return visible
    }

    private func getUnitsToCollide(_ unit: Unit) -> [Unit]? {
        var nearby: [Unit]? = nil
        let range = Unit.COLLISION_CHECK_DISTANCE
        let iStart = max(0, unit.physicalTilePos.x - range)
        let jStart = max(0, unit.physicalTilePos.y - range)
        let iFin    = min(m_map.physicalMapHeight,  unit.physicalTilePos.x + range)
        let jFin    = min(m_map.physicalMapWidth, unit.physicalTilePos.y + range)

        for i in iStart..<iFin {
            for j in jStart..<jFin {
                guard i < m_objectsToDraw.tabla.count, j < m_objectsToDraw.tabla[i].count,
                      let other = m_objectsToDraw.tabla[i][j] as? Unit, other !== unit else { continue }
                let dist = other.calculateDistance(unit.physicalTilePos.x,
                                                  unit.physicalTilePos.y)
                if dist <= Double(range) {
                    if nearby == nil { nearby = [] }
                    nearby!.append(other)
                }
            }
        }
        return nearby
    }

    private func attackVisibleUnits(_ unit: Unit) {
        guard let visible = m_visibleUnits else { return }
        for enemy in visible {
            if enemy.faction != m_faction, !enemy.isDead() {
                unit.attack(enemy)
            }
        }
    }

    func placeUnits(_ type: Int, _ count: Int, _ x: Int, _ y: Int) -> [Unit] {
        guard count > 0 else {
            Log.shared.error("No se puede crear un group de cantidad 0.")
            return []
        }

        var group:   [Unit] = []
        var i = 0, j = 0, inc = 2
        var dir = 1  // UP
        var placed = 0

        while placed < count {
            if m_map.isWalkable(x + i, y + j) {
                if let u = placeUnitInternal(type, x + i, y + j) {
                    group.append(u)
                }
                placed += 1
            }

            switch dir {
            case 1: i += 2; if i == inc { dir = 2 }
            case 2: j += 2; if j == inc { dir = 3 }
            case 3: i -= 2; if i == -inc { dir = 0 }
            case 0: j -= 2; if j == -inc { dir = 1; inc += 2 }
            default: break
            }
        }
        return group
    }

    private func placeUnitInternal(_ type: Int, _ i: Int, _ j: Int) -> Unit? {
        guard m_map.isWalkable(i, j) else {
            Log.shared.debug("No se puede position la unit: tile no caminable.")
            return nil
        }
        let unit = Unit(type)
        unit.physicalTilePos = (i, j)
        unit.previousTile         = (i, j)
        unit.initializeXY()
        unit.faction = m_faction

        m_units.append(unit)
        if i < m_objectsToDraw.tabla.count, j < m_objectsToDraw.tabla[i].count {
            m_objectsToDraw.tabla[i][j] = unit
        }
        return unit
    }

    func clearSelection() {
        m_selectedGroup?.isSelected = false
        m_selectedUnit?.isSelected = false
        m_hud.selectedUnit = nil
        m_selectedGroup   = nil
        m_selectedUnit  = nil
    }
}
