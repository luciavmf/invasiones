//
//  Player.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Jugador.cs — abstract base class for both game factions.
//

import Foundation

/// Abstract base class for both game factions (Argentine and Enemy).
/// Manages a list of units, handles objective assignment, and implements shared
/// combat logic including visibility checks, collision resolution, and unit updates.
class Player {

    // MARK: - Enums
    enum STATE { case START, LOADING, GAME }

    // MARK: - Protected attributes
    /// Whether the player has completed the current objective.
    var objectiveCompleted: Bool = false
    /// The faction this player controls.
    var faction: Episode.BANDO = .ARGENTINE
    /// Set to true when at least one unit completed its order in the current frame.
    var someoneCompletedOrder: Bool = false
    /// Animated ring displayed at the current order target position.
    var ring: AnimObject?

    var hud: Hud
    var units: [Unit] = []
    /// The shared object table indexed by physical tile position (updated each frame).
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
    /// The map object the player must collect (only valid for TAKE_OBJECT orders).
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

    func loadUnits(_ levelIndex: Int) throws { fatalError("loadUnits must be overridden") }

    // MARK: - Objective completion
    /// - Returns: `true` if the player has fulfilled the current objective.
    func completedObjective() -> Bool { objectiveCompleted }

    // MARK: - Set objective
    /// Assigns a new objective, distributes its first command to all units, and resets the completion flag.
    func setObjective(_ obj: Objective?) {
        objective = obj
        objectiveCompleted = false

        if let obj = objective {
            command = obj.nextCommand()

            if let ord = command {
                if ord.id == .TAKE_OBJECT, let img = ord.image {
                    objectToTake = MapObject(sup: img, i: ord.point.x, j: ord.point.y)
                }
                ring?.setPosition(i: ord.point.x, j: ord.point.y)
            }
        } else {
            command = nil
        }

        units.forEach { $0.setObjectiveCommand(ord: command) }
    }

    /// Advances to the next command within the current objective.
    /// Automatically processes and activates any TRIGGER commands before returning.
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
                    map.invalidateTile(x: ord.point.x, y: ord.point.y)

                    let anim2 = AnimObject(Animation(copia: anim.animation),
                                          ord.animation!.physicalTilePos.x - 5,
                                          ord.animation!.physicalTilePos.y - 5)
                    fireEffects!.append(anim2)
                    map.invalidateTile(x: anim.physicalTilePos.x - 5, y: anim.physicalTilePos.y - 5)

                    let anim3 = AnimObject(Animation(copia: anim.animation),
                                          ord.animation!.physicalTilePos.x - 5,
                                          ord.animation!.physicalTilePos.y)
                    fireEffects!.append(anim3)
                    map.invalidateTile(x: anim.physicalTilePos.x - 5, y: anim.physicalTilePos.y)
                }
                command = objective?.nextCommand()
                if command == nil { objectiveCompleted = true }
            }
            if let ord = command {
                ring?.setPosition(i: ord.point.x, j: ord.point.y)
            }
        }

        units.forEach { $0.setObjectiveCommand(ord: command) }
    }

    // MARK: - Unit update (shared)

    /// Updates all units: moves them, checks selections, resolves collisions, triggers attacks, and queues dead units.
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

    /// Removes all units marked dead this frame from the unit list and the object map.
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
                unit.evadeUnit(other: other, visible: visibleUnits)
            }
        }
    }

    /// Returns a list of units visible to `unit` and marks the corresponding tiles as visible on the map.
    /// - Parameter unit: The unit to check visibility from.
    /// - Returns: A list of visible units, or `nil` if none are found.
    func getVisibleUnitsAndTiles(_ unit: Unit) -> [Unit]? {
        var visible: [Unit]? = nil
        let iStart = max(0, unit.physicalTilePos.x - Unit.MAX_VISIBILITY)
        let jStart = max(0, unit.physicalTilePos.y - Unit.MAX_VISIBILITY)
        let iFin = min(map.physicalMapHeight, unit.physicalTilePos.x + Unit.MAX_VISIBILITY)
        let jFin = min(map.physicalMapWidth, unit.physicalTilePos.y + Unit.MAX_VISIBILITY)
        let esVisible = unit.isOnScreen()

        for i in iStart..<iFin {
            for j in jStart..<jFin {
                let dist = unit.calculateDistance(toI: i, toJ: j)
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
                let dist = other.calculateDistance(toI: unit.physicalTilePos.x,
                                                   toJ: unit.physicalTilePos.y)
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
                unit.attack(enemy: enemy)
            }
        }
    }

    /// Places `count` units of the given type in a spiral pattern around tile (x, y).
    /// - Parameters:
    ///   - type: The unit type identifier.
    ///   - count: The number of units to place.
    ///   - x: Target tile column (physical grid).
    ///   - y: Target tile row (physical grid).
    /// - Returns: The list of placed units.
    func placeUnits(type: Int, count: Int, x: Int, y: Int) -> [Unit] {
        guard count > 0 else {
            Log.shared.error("No se puede crear un group de cantidad 0.")
            return []
        }

        var group: [Unit] = []
        var i = 0, j = 0, inc = 2
        var dir = 1  // UP
        var placed = 0

        while placed < count {
            if map.isWalkable(x: x + i, y: y + j) {
                if let u = placeUnitInternal(type: type, i: x + i, j: y + j) {
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

    private func placeUnitInternal(type: Int, i: Int, j: Int) -> Unit? {
        guard map.isWalkable(x: i, y: j) else {
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

    /// Deselects the currently selected unit and/or group and clears the HUD selection.
    func clearSelection() {
        selectedGroup?.isSelected = false
        selectedUnit?.isSelected = false
        hud.selectedUnit = nil
        selectedGroup = nil
        selectedUnit = nil
    }
}
