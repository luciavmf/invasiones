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
    var objectiveCompleted: Bool = false
    var faction: Episode.BANDO = .ARGENTINE
    var someoneCompletedOrder: Bool = false
    var ring: AnimObject?

    var hud: Hud
    var units: [Unit] = []
    var objectsToDraw: ObjectTable     // [physicalMapHeight][physicalMapWidth]
    var map: Map
    var groups: [Group]? = nil
    var stateValue: STATE = .START
    var camera: Camera
    var selectedUnits: [Unit] = []
    var deadUnits: [Unit]? = nil
    var visibleUnits: [Unit]? = nil
    var collidingUnits: [Unit]? = nil
    var selectedUnit: Unit?
    var selectedGroup: Group?
    var objective: Objective?
    var command: Command?
    var objectToTake: MapObject?
    var fireEffects: [AnimObject]? = nil

    var unitCount: Int { units.count }

    // MARK: - Initializer
    init(map mapArg: Map, camera cameraArg: Camera, objectsToDraw tableArg: ObjectTable, hud hudArg: Hud) {
        self.map = mapArg
        self.camera = cameraArg
        self.objectsToDraw = tableArg
        self.hud = hudArg
    }

    // MARK: - Abstract methods (deben ser sobreescritos)
    func update() { fatalError("update() must be overridden") }
    func loadUnits(_ levelIndex: Int) -> Bool { fatalError("loadUnits must be overridden") }

    // MARK: - Objective completion
    func completedObjective() -> Bool { objectiveCompleted }

    // MARK: - Set objective
    func setObjective(_ obj: Objective?) {
        objective = obj
        objectiveCompleted = false

        if let obj = objective {
            command = obj.nextCommand()

            if let ord = command {
                if ord.id == .TAKE_OBJECT, let img = ord.image {
                    objectToTake = MapObject(sup: img, i: ord.point.x, j: ord.point.y)
                }
                ring?.setPosition(ord.point.x, ord.point.y)
            }
        } else {
            command = nil
        }

        units.forEach { $0.setObjectiveCommand(command) }
    }

    func setNextCommand() {
        someoneCompletedOrder = false
        command = objective?.nextCommand()

        if command == nil {
            objectiveCompleted = true
        } else {
            // Automatically process TRIGGERs
            while let ord = command, ord.id == .TRIGGER {
                if fireEffects == nil { fireEffects = [] }
                if let anim = ord.animation {
                    fireEffects!.append(anim)
                    map.invalidateTile(ord.point.x, ord.point.y)

                    let anim2 = AnimObject(Animation(copia: anim.animation),
                                          ord.animation!.physicalTilePos.x - 5,
                                          ord.animation!.physicalTilePos.y - 5)
                    fireEffects!.append(anim2)
                    map.invalidateTile(anim.physicalTilePos.x - 5, anim.physicalTilePos.y - 5)

                    let anim3 = AnimObject(Animation(copia: anim.animation),
                                          ord.animation!.physicalTilePos.x - 5,
                                          ord.animation!.physicalTilePos.y)
                    fireEffects!.append(anim3)
                    map.invalidateTile(anim.physicalTilePos.x - 5, anim.physicalTilePos.y)
                }
                command = objective?.nextCommand()
                if command == nil { objectiveCompleted = true }
            }
            if let ord = command {
                ring?.setPosition(ord.point.x, ord.point.y)
            }
        }

        units.forEach { $0.setObjectiveCommand(command) }
    }

    // MARK: - Unit update (shared)

    func updateUnits() {
        deadUnits = nil
        let checkSelection = selectedUnit == nil && selectedGroup == nil

        for unit in units {
            updateAndMoveUnitInObjectMap(unit)

            if checkSelection, unit.isSelected {
                if selectedUnits.count < 6 {
                    hud.selectedUnit = unit
                    selectedUnits.append(unit)
                } else {
                    unit.isSelected = false
                }
            }

            visibleUnits = getVisibleUnitsAndTiles(unit)

            if unit.isMoving() {
                checkCollisions(unit)
            }

            if unit.currentState == .IDLE || unit.currentState == .PATROLLING {
                attackVisibleUnits(unit)
            }

            if unit.currentState == .DEAD {
                if deadUnits == nil { deadUnits = [] }
                deadUnits!.append(unit)
            }

            if unit.completedOrder { someoneCompletedOrder = true }
        }

        // Check KILL order
        if let ord = command, ord.id == .KILL {
            someoneCompletedOrder = true
            let iStart = ord.point.x - ord.width
            let iEnd = ord.point.x + ord.width
            let jStart = ord.point.y - ord.width
            let jEnd = ord.point.y + ord.width

            for i in iStart..<iEnd {
                for j in jStart..<jEnd {
                    guard i >= 0, j >= 0, i < objectsToDraw.tabla.count,
                          j < objectsToDraw.tabla[i].count else { continue }
                    if let u = objectsToDraw.tabla[i][j] as? Unit, u.faction == .ENEMY {
                        someoneCompletedOrder = false
                    }
                }
            }
        }
    }

    func removeDeadUnits() {
        guard let muertas = deadUnits else { return }
        for dead in muertas {
            let ti = dead.physicalTilePos.x
            let tj = dead.physicalTilePos.y
            if ti < objectsToDraw.tabla.count, tj < objectsToDraw.tabla[ti].count {
                objectsToDraw.tabla[ti][tj] = nil
            }
            units.removeAll { $0 === dead }
        }
    }

    // MARK: - Private

    private func updateAndMoveUnitInObjectMap(_ unit: Unit) {
        let moved = unit.update()
        if moved {
            let prevI = unit.previousTile.x
            let prevJ = unit.previousTile.y
            if prevI < objectsToDraw.tabla.count, prevJ < objectsToDraw.tabla[prevI].count {
                if objectsToDraw.tabla[prevI][prevJ] === unit {
                    objectsToDraw.tabla[prevI][prevJ] = nil
                }
            }
            let ni = unit.physicalTilePos.x
            let nj = unit.physicalTilePos.y
            if ni < objectsToDraw.tabla.count, nj < objectsToDraw.tabla[ni].count {
                objectsToDraw.tabla[ni][nj] = unit
            }
        }
    }

    private func checkCollisions(_ unit: Unit) {
        collidingUnits = getUnitsToCollide(unit)
        for other in (collidingUnits ?? []) {
            if unit.hasCollision(other) {
                unit.evadeUnit(other, visibleUnits)
            }
        }
    }

    func getVisibleUnitsAndTiles(_ unit: Unit) -> [Unit]? {
        var visible: [Unit]? = nil
        let iStart = max(0, unit.physicalTilePos.x - Unit.MAX_VISIBILITY)
        let jStart = max(0, unit.physicalTilePos.y - Unit.MAX_VISIBILITY)
        let iFin = min(map.physicalMapHeight, unit.physicalTilePos.x + Unit.MAX_VISIBILITY)
        let jFin = min(map.physicalMapWidth, unit.physicalTilePos.y + Unit.MAX_VISIBILITY)
        let esVisible = unit.isOnScreen()

        for i in iStart..<iFin {
            for j in jStart..<jFin {
                let dist = unit.calculateDistance(i, j)
                guard dist <= Double(unit.visibility) else { continue }

                if i < objectsToDraw.tabla.count, j < objectsToDraw.tabla[i].count,
                   let other = objectsToDraw.tabla[i][j] as? Unit, other !== unit {
                    if visible == nil { visible = [] }
                    visible!.append(other)
                }

                if esVisible && unit.faction == .ARGENTINE {
                    map.visibleTilesLayer[i][j] = Int16(Map.TILE_VISIBLE)
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
        let iFin = min(map.physicalMapHeight, unit.physicalTilePos.x + range)
        let jFin = min(map.physicalMapWidth, unit.physicalTilePos.y + range)

        for i in iStart..<iFin {
            for j in jStart..<jFin {
                guard i < objectsToDraw.tabla.count, j < objectsToDraw.tabla[i].count,
                      let other = objectsToDraw.tabla[i][j] as? Unit, other !== unit else { continue }
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
        guard let visible = visibleUnits else { return }
        for enemy in visible {
            if enemy.faction != faction, !enemy.isDead() {
                unit.attack(enemy)
            }
        }
    }

    func placeUnits(_ type: Int, _ count: Int, _ x: Int, _ y: Int) -> [Unit] {
        guard count > 0 else {
            Log.shared.error("No se puede crear un group de cantidad 0.")
            return []
        }

        var group: [Unit] = []
        var i = 0, j = 0, inc = 2
        var dir = 1  // UP
        var placed = 0

        while placed < count {
            if map.isWalkable(x + i, y + j) {
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
        guard map.isWalkable(i, j) else {
            Log.shared.debug("No se puede position la unit: tile no caminable.")
            return nil
        }
        let unit = Unit(type)
        unit.physicalTilePos = (i, j)
        unit.previousTile = (i, j)
        unit.initializeXY()
        unit.faction = faction

        units.append(unit)
        if i < objectsToDraw.tabla.count, j < objectsToDraw.tabla[i].count {
            objectsToDraw.tabla[i][j] = unit
        }
        return unit
    }

    func clearSelection() {
        selectedGroup?.isSelected = false
        selectedUnit?.isSelected = false
        hud.selectedUnit = nil
        selectedGroup = nil
        selectedUnit = nil
    }
}
