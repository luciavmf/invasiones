//
//  Unit.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Unidad.cs (multiple partial files merged) — represents a unit in the game.
//

import Foundation

/// Represents a single unit (soldier) in the game.
/// Manages its own state machine (idle, moving, patrolling, attacking, pursuing, healing, dying),
/// pathfinding, formation offsets, collision evasion, and sprite animation.
class Unit: MapObject {

    // MARK: - Constants
    enum Constants {
        /// Maximum tile radius a unit can see other units.
        static let maxVisibility = 15
        /// Tile radius within which collision checks are performed.
        static let collisionCheckDistance = 4
        /// Minimum number of tiles away a patrol destination can be from the base position.
        static let patrolRandomMin = 8
        /// Maximum number of tiles away a patrol destination can be from the base position.
        static let patrolRandomMax = 16
        /// Minimum tile distance to the objective for a MOVE order to be considered fulfilled.
        static let minTilesToCompleteMove = 3
        /// Width of the selection/health bar drawn above the unit when selected.
        static let selectionBarWidth = 20
        /// Vertical offset of the selection bar relative to the unit's screen y coordinate.
        static let selectionBarY = -3
        /// Number of ticks the unit's corpse remains visible on screen before disappearing.
        static let deathFrameCount = 150
    }

    // MARK: - Enums
    /// States in which a unit can exist.
    enum State {
        case idle, moving, dying, attacking, pursuingUnit, dead, patrolling, healing
    }

    /// Sub-states used within the moving state.
    enum Substep {
        case incrementStep, dodgeUnit, reachStep, completedStep
    }

    // MARK: - Attributes
    /// The unit type index (e.g. UNIDAD_PATRICIO or UNIDAD_INGLES).
    private var type: Int = 0
    private var substate: Substep = .incrementStep
    /// The faction this unit belongs to.
    var faction: Episode.Faction = .enemy
    /// The unit currently being evaded after a collision.
    private(set) var unitToEvade: Unit?
    /// Current health points.
    private(set) var health: Int = 100
    /// Maximum health points (loaded from CSV).
    private(set) var resistancePoints: Int = 100
    /// Damage dealt per attack (always applied in full — accuracy roll was never implemented).
    private(set) var attackPoints: Int = 10
    /// Tile radius within which enemy units are detected.
    private(set) var visibility: Int = 10
    /// Accuracy stat loaded from CSV (not used in attack logic).
    private(set) var aim: Int = 5
    private var attackRange: Int = 5
    /// Number of frames between consecutive attacks.
    private(set) var attackInterval: Int = 30
    private var currentSpeed: (x: Int, y: Int) = (2, 2)
    private var defaultSpeedVec: (x: Int, y: Int) = (2, 2)
    private var enemy: Unit?
    private var stateValue: State = .idle
    private var nextStateValue: State = .idle
    private var direction: Int = 0  // 0=N, 1=NE, 2=E, 3=SE, 4=S, 5=SO, 6=O, 7=NO
    /// The remaining path to follow, stored as a stack (popLast = next step).
    private(set) var pathToFollow: [(i: Int, j: Int)]? = nil
    /// The tile the unit is currently moving toward.
    private(set) var nextTile: (x: Int, y: Int) = (0, 0)
    private var nextStep: (x: Int, y: Int) = (0, 0)
    /// Whether the unit is currently selected by the player.
    var isSelected: Bool = false
    private var mode: Int = 0
    private var sprite: Sprite?
    private var count: Int = 0
    private var targetPos: (x: Int, y: Int) = (-1, -1)
    /// The unit's display name (loaded from the CSV file).
    private(set) var name: String = ""
    /// The avatar image shown in the HUD when this unit is selected.
    private(set) var avatar: Surface?
    private var command: Command?
    /// The objective-level command used to determine whether the unit has fulfilled its mission.
    private var objectiveCommand: Command?
    /// Set to `true` when the unit has fulfilled its assigned order this frame.
    private(set) var completedOrder: Bool = false
    /// The base tile position used as the centre of the patrol area.
    private var patrolPosition: (x: Int, y: Int) = (0, 0)
    private var desiredPosition: (x: Int, y: Int) = (0, 0)  // offset en formación
    private var firstSprite: Int = 0
    /// Number of ticks between each health recovery tick.
    private var ticksPerRecovery: Int = 50
    /// Health points restored per recovery tick.
    private var recoveryPoints: Int = 20
    private var recoveryTicks: Int = 0
    private var isCommander: Bool = false
    private var group: Group?
    private var completedObjectiveOrder: Bool = false

    // Continuous world position for smooth movement
    private var posX: Double = 0
    private var posY: Double = 0

    // MARK: - Public properties

    var currentState: State { stateValue }
    /// The attack range of the unit in tiles.
    var range: Int { attackRange }
    /// The current movement speed vector.
    var speed: (x: Int, y: Int) { currentSpeed }
    /// The base movement speed loaded from the unit CSV.
    var defaultSpeed: Int { defaultSpeedVec.x }
    /// The offset within the formation used for flocking/grouping calculations.
    var formationOffset: (x: Int, y: Int) {
        get { desiredPosition }
        set { desiredPosition = newValue }
    }

    // MARK: - Initializeres

    override init() {
        super.init()
    }

    /// Template copy initializer (id = index in unitTypes).
    init(_ id: Int) {
        super.init()
        let types = ResourceManager.shared.unitTypes
        guard id >= 0, id < types.count, let copia = types[id] else {
            Log.shared.debug("Unit copy not loaded: id=\(id)")
            return
        }
        type = copia.type
        currentSpeed = copia.currentSpeed
        defaultSpeedVec = copia.currentSpeed
        health = copia.resistancePoints
        resistancePoints = copia.resistancePoints
        attackPoints = copia.attackPoints
        visibility = copia.visibility
        aim = copia.aim
        attackRange = copia.attackRange
        attackInterval = copia.attackInterval
        avatar = copia.avatar
        name = copia.name
        ticksPerRecovery = copia.ticksPerRecovery
        recoveryPoints = copia.recoveryPoints

        // Clone sprite
        if let s = copia.sprite {
            sprite = Sprite(copia: s)
        }
    }

    // MARK: - Main update

    /// Updates the unit. Returns true if it moved on the physical map.
    @discardableResult
    override func update() -> Bool {
        guard stateValue != .dead else { return false }

        var movedOnMap = false
        completedOrder = false

        switch stateValue {
        case .idle:
            updateIdleAnimation()
        case .moving:
            movedOnMap = updateMovingState()
        case .patrolling:
            movedOnMap = updatePatrollingState()
        case .pursuingUnit:
            updatePursuingUnitState()
        case .attacking:
            updateAttackingState()
        case .dying:
            updateDyingState()
        case .dead:
            break
        case .healing:
            updateHealingState()
        }

        // Check if the objective order was fulfilled
        checkOrderCompleted()

        super.update()
        dibujarSpriteActual()
        return movedOnMap
    }

    override func draw(_ g: Video) {
        // Selection (health bar) is drawn here
        if isSelected {
            let healthFraction = Double(health) / Double(max(resistancePoints, 1))
            let barWidth = Int(Double(Constants.selectionBarWidth) * healthFraction)
            g.setColor(GameColor.green)
            g.fillRect(x - Constants.selectionBarWidth / 2,
                               y + Constants.selectionBarY,
                               barWidth, 3)
            g.setColor(GameColor.red)
            g.fillRect(x - Constants.selectionBarWidth / 2 + barWidth,
                               y + Constants.selectionBarY,
                               Constants.selectionBarWidth - barWidth, 3)
        }
        sprite?.draw(g: g, x: x - (sprite?.frameWidth ?? 0) / 2,
                     y: y - (sprite?.frameHeight ?? 0))
    }

    // MARK: - Public orders

    /// Orders the unit to move to tile (x, y), computing a path via A*.
    func move(x: Int, y: Int) {
        command = Command(.move, x, y)
        setState(.moving)
        nextStateValue = .idle

        let path = PathFinder.shared.findShortestPath(
            startI: physicalTilePos.x, startJ: physicalTilePos.y, targetI: x, targetJ: y)

        if let c = path, !c.isEmpty {
            // First element is destination, last is origin. Used as a stack (popLast = next step).
            pathToFollow = Array(c.dropLast())   // quita el nodo start (último = origen)
        } else {
            setState(.idle)
            pathToFollow = nil
            return
        }

        substate = .incrementStep
    }

    /// Puts the unit into patrol mode, wandering randomly around its starting tile.
    func patrol() {
        setState(.patrolling)
        nextStateValue = .patrolling
        patrolPosition = physicalTilePos
        pathToFollow = findRandomPatrolPath(
            i: physicalTilePos.x, j: physicalTilePos.y)
    }

    /// Orders the unit to pursue and attack the given enemy unit.
    func attack(enemy: Unit) {
        self.enemy = enemy
        targetPos = (-1, -1)
        setState(.pursuingUnit)
    }

    /// Halts the unit immediately, clearing its path and returning it to idle.
    func stop() {
        setState(.idle)
        pathToFollow = nil
    }

    /// Sets the objective-level command used to determine whether the unit has fulfilled its mission.
    func setObjectiveCommand(ord: Command?) {
        completedOrder = false
        objectiveCommand = ord
    }

    /// Puts the unit into the healing state so it regenerates health over time.
    func recoverHealth() {
        setState(.healing)
    }

    // MARK: - Collision and evasion

    /// Returns `true` if this unit and `other` occupy overlapping tiles.
    func hasCollision(_ other: Unit) -> Bool {
        let dx = abs(physicalTilePos.x - other.physicalTilePos.x)
        let dy = abs(physicalTilePos.y - other.physicalTilePos.y)
        return dx < 2 && dy < 2
    }

    /// Triggers the evasion sub-state so the unit recalculates its path around `other`.
    func evadeUnit(other: Unit, visible: [Unit]?) {
        unitToEvade = other
        substate = .dodgeUnit
    }

    // MARK: - Queries

    /// Returns `true` if the unit is dead or in the dying animation.
    func isDead() -> Bool { stateValue == .dead || stateValue == .dying }

    /// Returns `true` if the unit is in any active movement state (moving, patrolling, or pursuing).
    func isMoving() -> Bool {
        return stateValue == .moving || stateValue == .patrolling || stateValue == .pursuingUnit
    }

    /// Returns `true` if the unit's screen position falls within the camera's visible area.
    func isOnScreen() -> Bool {
        guard let cam = MapObject.camera else { return false }
        return x >= cam.startX && x <= cam.startX + cam.width &&
               y >= cam.startY && y <= cam.startY + cam.height
    }

    /// Calculates the Euclidean distance in tile units from this unit to tile (toI, toJ).
    func calculateDistance(toI: Int, toJ: Int) -> Double {
        let di = Double(physicalTilePos.x - toI)
        let dj = Double(physicalTilePos.y - toJ)
        return sqrt(di * di + dj * dj)
    }

    /// Returns `true` if the unit is close enough to its objective tile to count the MOVE order as fulfilled.
    func completedMoveObjective() -> Bool {
        guard let ord = objectiveCommand else { return false }
        let dist = calculateDistance(toI: ord.point.x, toJ: ord.point.y)
        return dist <= Double(Constants.minTilesToCompleteMove)
    }

    // MARK: - Group / formation

    /// Returns `true` if the unit currently belongs to a group.
    var belongsToGroup: Bool { group != nil }
    /// The group this unit belongs to, or `nil` if it is operating independently.
    var myGroup: Group? { group }

    /// Registers this unit as a member of `group`.
    func joinGroup(_ group: Group) {
        self.group = group
    }

    /// Removes this unit from its current group.
    func leaveGroup() {
        group = nil
    }

    /// Marks this unit as the group commander (its path determines group movement).
    func markAsCommander() {
        isCommander = true
    }

    /// Removes the commander designation from this unit.
    func unmarkCommander() {
        isCommander = false
    }

    /// Calculates this unit's path by offsetting the commander's path by (offsetX, offsetY) tiles,
    /// finding detours through A* for any non-walkable positions.
    /// - Parameters:
    ///   - commanderPath: The path the group commander is following.
    ///   - offsetX: Formation tile offset along the i axis.
    ///   - offsetY: Formation tile offset along the j axis.
    func calculatePathAtDistance(commanderPath: [(i: Int, j: Int)],
                                 offsetX: Int, offsetY: Int) {
        guard let map = MapObject.map else { return }

        setState(.moving)
        nextStateValue = .idle

        // Build offset copy of commander's path.
        // commanderPath: [0]=destination, [last]=first step (Swift format).
        // Iterate reversed so pathCopy[0]=first step, ..., [last]=destination (same order as C# Stack).
        let pathCopy: [(i: Int, j: Int)] = commanderPath.reversed().map { (i: $0.i + offsetX, j: $0.j + offsetY) }

        var pathList: [(i: Int, j: Int)] = []
        var idx = 0

        while idx < pathCopy.count {
            let point = pathCopy[idx]
            if !map.isWalkable(x: point.i, y: point.j) {
                if idx > 0 {
                    let prevIdx = idx - 1
                    guard let nextValidIdx = findNextValidPosition(pathCopy, from: idx) else {
                        // No more valid points ahead — stop here
                        idx = pathCopy.count
                        continue
                    }
                    idx = nextValidIdx

                    var newPath = PathFinder.shared.findShortestPath(
                        startI: pathCopy[prevIdx].i, startJ: pathCopy[prevIdx].j,
                        targetI: pathCopy[idx].i,    targetJ: pathCopy[idx].j)

                    if newPath == nil {
                        guard let prevValidIdx = findPrevValidPosition(pathCopy, from: nextValidIdx) else {
                            Log.shared.debug("Unit: no valid path found.")
                            pathToFollow = []
                            return
                        }
                        idx = prevValidIdx
                        newPath = PathFinder.shared.findShortestPath(
                            startI: pathCopy[prevIdx].i, startJ: pathCopy[prevIdx].j,
                            targetI: pathCopy[idx].i,    targetJ: pathCopy[idx].j)
                    }

                    guard let segment = newPath else {
                        pathToFollow = []
                        return
                    }
                    // segment: [0]=destination, [last]=origin — append in Pop order (reversed)
                    pathList.append(contentsOf: segment.reversed())
                } else {
                    idx += 1
                }
            } else {
                pathList.append(point)
                idx += 1
            }
        }

        // pathList is first-step→destination; store as Swift path array ([0]=destination, [last]=first-step)
        pathToFollow = pathList.reversed()
        substate = .incrementStep
    }

    private func findNextValidPosition(_ list: [(i: Int, j: Int)], from start: Int) -> Int? {
        guard let map = MapObject.map else { return nil }
        var idx = start
        while idx < list.count, !map.isWalkable(x: list[idx].i, y: list[idx].j) {
            idx += 1
        }
        if idx >= list.count { return nil }
        // Skip up to two extra steps, same as C# logic
        if idx < list.count - 1 {
            let next = list[idx + 1]
            if map.isWalkable(x: next.i, y: next.j) {
                idx += 1
                if idx < list.count - 1 {
                    let next2 = list[idx + 1]
                    if map.isWalkable(x: next2.i, y: next2.j) {
                        idx += 1
                    }
                }
            }
        }
        return idx
    }

    private func findPrevValidPosition(_ list: [(i: Int, j: Int)], from start: Int) -> Int? {
        guard let map = MapObject.map else { return nil }
        var idx = start
        while idx >= 0, !map.isWalkable(x: list[idx].i, y: list[idx].j) {
            idx -= 1
        }
        if idx < 0 { return nil }
        return idx
    }

    /// Returns `true` if the mouse cursor is currently over this unit's sprite bounding box.
    func isUnderMouse() -> Bool {
        let mx = Int(Mouse.shared.X)
        let my = Int(Mouse.shared.Y)
        let fw = sprite?.frameWidth ?? (frameWidth > 0 ? frameWidth : 20)
        let fh = sprite?.frameHeight  ?? (frameHeight  > 0 ? frameHeight  : 30)
        let hw = fw / 2
        return mx >= x - hw && mx <= x + hw && my >= y - fh && my <= y
    }

    /// Orders the unit to move toward the infirmary at (x, y) and then heal.
    func heal(x: Int, y: Int) {
        command = Command(.heal, x, y)

        guard let map = MapObject.map else { return }
        let p = map.getLineOfSightPosition(x1: x, x2: physicalTilePos.x, y1: y, y2: physicalTilePos.y)
        if p.x == -1 {
            Log.shared.debug("Unit: cannot send to heal.")
            return
        }
        setHealing(x: p.x, y: p.y)
    }

    private func setHealing(x: Int, y: Int) {
        setState(.moving)
        nextStateValue = .healing

        let path = PathFinder.shared.findShortestPath(
            startI: physicalTilePos.x, startJ: physicalTilePos.y, targetI: x, targetJ: y)

        if let c = path, !c.isEmpty {
            pathToFollow = Array(c.dropLast())
        } else {
            Log.shared.debug("Unit: no path found to heal location.")
            setState(.idle)
            pathToFollow = nil
            return
        }
        substate = .incrementStep
    }

    // MARK: - Selección por arrastre de mouse (rectangle)
    /// Selects the unit if its sprite overlaps the drag-selection rectangle.
    /// - Returns: `true` if the unit was selected.
    func selectIfInRect(x: Int, y: Int, w: Int, h: Int) -> Bool {
        let fw = sprite?.frameWidth ?? (frameWidth > 0 ? frameWidth : 20)
        let fh = sprite?.frameHeight  ?? (frameHeight  > 0 ? frameHeight  : 30)
        // In Swift, x = sprite horizontal center, y = sprite bottom.
        // Sprite bounds: left = x-fw/2, right = x+fw/2, top = y-fh, bottom = y.
        // Matches the original C# check (translated from top-left convention to center/bottom).
        let inRange = x <= x - fw / 2
                  && y <= y - fh / 2
                  && x + w > x + fw / 2
                  && y + h > y
        if inRange { isSelected = true }
        return inRange
    }

    // MARK: - Private

    private func setState(_ e: State) {
        stateValue = e
        count = 0
        if e == .idle {
            pathToFollow = nil
        }
        if e == .attacking {
            enemy?.counterAttack(self)
        }
    }

    /// Called when this unit starts being attacked. If idle and in range, counter-attacks.
    func counterAttack(_ attacker: Unit) {
        guard stateValue == .idle else { return }
        Log.shared.debug("Unit: under attack, counter-attacking.")
        enemy = attacker
        if calculateDistance(toI: attacker.physicalTilePos.x, toJ: attacker.physicalTilePos.y) < Double(attackRange) {
            aimAtUnit(attacker)
            setState(.attacking)
        }
    }

    private func updateIdleAnimation() {
        sprite?.update()
        let anim = firstAnimation() + direction
        sprite?.setAnimation(anim: anim)
        sprite?.play()
    }

    private func dibujarSpriteActual() {
        sprite?.update()
    }

    private func firstAnimation() -> Int {
        switch stateValue {
        case .idle, .healing:
            return type == 0 ? Res.SPR_ANIM_PATRICIO_QUIETO_N : Res.SPR_ANIM_INGLES_QUIETO_N
        case .moving, .pursuingUnit, .patrolling:
            return type == 0 ? Res.SPR_ANIM_PATRICIO_CAMINA_N : Res.SPR_ANIM_INGLES_CAMINA_N
        case .dying, .dead:
            return type == 0 ? Res.SPR_ANIM_PATRICIO_MUERE_N : Res.SPR_ANIM_INGLES_MUERE_N
        case .attacking:
            return type == 0 ? Res.SPR_ANIM_PATRICIO_ATACA_N : Res.SPR_ANIM_INGLES_ATACA_N
        }
    }

    // MARK: - Movement

    private func updateMovingState() -> Bool {
        return moverse()
    }

    private func updatePatrollingState() -> Bool {
        if pathToFollow == nil {
            pathToFollow = findRandomPatrolPath(i: physicalTilePos.x, j: physicalTilePos.y)
        }
        return moverse()
    }

    private func moverse() -> Bool {
        switch substate {
        case .incrementStep:
            guard let path = pathToFollow, !path.isEmpty else {
                setState(nextStateValue)
                pathToFollow = nil
                return false
            }
            nextTile = (path.last!.i, path.last!.j)
            pathToFollow!.removeLast()
            nextStep = tileToWorld(i: nextTile.x, j: nextTile.y)
            substate = .reachStep

        case .dodgeUnit:
            recalculateNextStep()
            substate = .reachStep
            return true

        default: break
        }

        let dir = getDirection(targetX: nextStep.x, targetY: nextStep.y)
        if dir != -1 { direction = dir }

        // Update walking animation
        let anim = firstAnimation() + direction
        sprite?.setAnimation(anim: anim)
        sprite?.play()

        let arrived = moveToNextStep()

        if arrived {
            let prevTile = physicalTilePos
            previousTile = prevTile
            physicalTilePos = nextTile
            substate = .incrementStep
            return true
        }
        return false
    }

    /// Moves one step toward nextStep using Euclidean normalization.
    /// Direction-based per-axis velocity (C# parity) is not used here because in the isometric
    /// coordinate system adjacent tiles have unequal dx/dy (e.g. SE tile: dx=+16, dy=+8),
    /// so applying equal vx/vy per direction overshoots the shorter axis and causes visual jitter.
    private func moveToNextStep() -> Bool {
        let spd = defaultSpeedVec.x

        let dx = nextStep.x - worldPos.x
        let dy = nextStep.y - worldPos.y
        let dist = sqrt(Double(dx * dx + dy * dy))

        if dist <= Double(spd) {
            worldPos = nextStep
            // Keep currentSpeed consistent for any callers that read it.
            currentSpeed = (dx, dy)
            return true
        }

        let ratio = Double(spd) / dist
        let vx = Int(Double(dx) * ratio)
        let vy = Int(Double(dy) * ratio)
        currentSpeed = (vx, vy)
        worldPos.x += vx
        worldPos.y += vy
        return false
    }

    private func recalculateNextStep() {
        // Snap back to the current tile (undo partial movement toward the blocked step).
        worldPos = tileToWorld(i: physicalTilePos.x, j: physicalTilePos.y)
        unitToEvade = nil

        guard pathToFollow != nil, !pathToFollow!.isEmpty else {
            setLastPosition()
            return
        }

        // Pop the tile we were heading to (now blocked) and find a detour.
        var nextTileIJ = pathToFollow!.removeLast()

        var newPath = PathFinder.shared.findShortestPath(
            startI: physicalTilePos.x, startJ: physicalTilePos.y,
            targetI: nextTileIJ.i, targetJ: nextTileIJ.j)

        // If no path, keep popping further waypoints until one is reachable.
        while newPath == nil {
            guard pathToFollow != nil, !pathToFollow!.isEmpty else {
                Log.shared.debug("Unit: no alternative path found.")
                setLastPosition()
                return
            }
            nextTileIJ = pathToFollow!.removeLast()
            newPath = PathFinder.shared.findShortestPath(
                startI: physicalTilePos.x, startJ: physicalTilePos.y,
                targetI: nextTileIJ.i, targetJ: nextTileIJ.j)
        }

        // newPath: [last] = first step toward nextTileIJ, [0] = nextTileIJ.
        var detour = newPath!
        let primerPaso = detour.removeLast()          // consume first step
        nextTile = (primerPaso.i, primerPaso.j)
        nextStep = tileToWorld(i: nextTile.x, j: nextTile.y)

        // Prepend remaining detour steps before the original remaining path
        // (equivalent to PathFinder.AdherirCamino in C#).
        pathToFollow = (pathToFollow ?? []) + detour
    }

    private func setLastPosition() {
        nextTile = physicalTilePos
        nextStep = tileToWorld(i: nextTile.x, j: nextTile.y)
    }

    private func getDirection(targetX: Int, targetY: Int) -> Int {
        let dx = targetX - worldPos.x
        let dy = targetY - worldPos.y
        if dx == 0 && dy == 0 { return -1 }

        let angle = atan2(Double(dy), Double(dx)) * 180.0 / Double.pi
        // SpriteKit Y is flipped vs game-world Y; map to 8 compass dirs
        let normalized = angle < 0 ? angle + 360 : angle
        let index = Int((normalized + 22.5) / 45.0) % 8
        // angle=0 → E=2, 45 → SE=3, 90 → S=4, 135 → SO=5, 180 → O=6, 225 → NO=7, 270 → N=0, 315 → NE=1
        let mapping = [2, 3, 4, 5, 6, 7, 0, 1]
        return mapping[index]
    }

    // MARK: - Patrolling

    private func findRandomPatrolPath(i: Int, j: Int) -> [(i: Int, j: Int)]? {
        guard let map = MapObject.map else { return nil }
        let range = Constants.patrolRandomMax - Constants.patrolRandomMin
        // Mirror original C#: loop until a valid path is found.
        // Use the stored patrol base position as the destination origin (not current pos).
        var path: [(i: Int, j: Int)]? = nil
        var attempts = 0
        while path == nil && attempts < 20 {
            attempts += 1
            let offI = Int.random(in: 0..<range) + Constants.patrolRandomMin
            let offJ = Int.random(in: 0..<range) + Constants.patrolRandomMin
            let signI = Bool.random() ? 1 : -1
            let signJ = Bool.random() ? 1 : -1
            let destI = patrolPosition.x + signI * offI
            let destJ = patrolPosition.y + signJ * offJ
            guard map.isWalkable(x: destI, y: destJ) else { continue }
            path = PathFinder.shared.findShortestPath(startI: i, startJ: j, targetI: destI, targetJ: destJ)
        }
        return path
    }

    // MARK: - Pursuit and attack

    private func updatePursuingUnitState() {
        guard let enemy = enemy else {
            setState(.idle)
            return
        }
        if enemy.isDead() {
            self.enemy = nil
            setState(.idle)
            return
        }

        let dist = calculateDistance(toI: enemy.physicalTilePos.x, toJ: enemy.physicalTilePos.y)

        if dist <= Double(attackRange) {
            // In range: attack
            aimAtUnit(enemy)
            setState(.attacking)
        } else {
            // Move closer
            if pathToFollow == nil || targetPos != enemy.physicalTilePos {
                targetPos = enemy.physicalTilePos
                move(x: enemy.physicalTilePos.x, y: enemy.physicalTilePos.y)
            } else {
                _ = moverse()
            }
        }

        let anim = firstAnimation() + direction
        sprite?.setAnimation(anim: anim)
        sprite?.play()
    }

    private func updateAttackingState() {
        guard let enemy = enemy else {
            setState(.idle)
            return
        }
        if enemy.isDead() {
            self.enemy = nil
            setState(.idle)
            return
        }

        count += 1
        let anim = firstAnimation() + direction
        sprite?.setAnimation(anim: anim)
        sprite?.play()

        if count >= attackInterval {
            count = 0
            let hit = calculateDamage()
            if hit > 0 {
                enemy.takeDamage(hit)
                playShotSound()
            }
        }

        // Resume pursuit if it moved away
        let dist = calculateDistance(toI: enemy.physicalTilePos.x, toJ: enemy.physicalTilePos.y)
        if dist > Double(attackRange) {
            setState(.pursuingUnit)
        }
    }

    private func aimAtUnit(_ enemy: Unit) {
        self.enemy = enemy
        let di = enemy.physicalTilePos.x - physicalTilePos.x
        let dj = enemy.physicalTilePos.y - physicalTilePos.y
        // Convertir di/dj a dirección de sprite (8 dirs)
        let angle = atan2(Double(dj), Double(di)) * 180.0 / Double.pi
        let normalized = angle < 0 ? angle + 360 : angle
        let index = Int((normalized + 22.5) / 45.0) % 8
        let mapping = [2, 3, 4, 5, 6, 7, 0, 1]
        direction = mapping[index]
    }

    private func calculateDamage() -> Int {
        return attackPoints
    }

    /// Applies `danio` points of damage to this unit, triggering death if health reaches zero.
    func takeDamage(_ danio: Int) {
        health -= danio
        if health <= 0 {
            health = 0
            morir()
        }
    }

    /// Transitions the unit into the dying state and plays the death sound.
    func morir() {
        Log.shared.debug("Unit: died.")
        setState(.dying)
        enemy = nil
        if type == Res.UNIDAD_PATRICIO {
            Sound.shared.play(id: Res.SFX_MUERTE_PATRICIO, loop: 0)
        }
    }

    private func updateDyingState() {
        if count == 0 {
            let anim = firstAnimation() + direction
            sprite?.setAnimation(anim: anim)
            sprite?.loop = false
            sprite?.play()
        }

        if sprite?.isAnimationDone() == true {
            sprite?.setFrame(sprite!.frameCount - 1)
            sprite?.stop()
        }

        count += 1
        if count >= Constants.deathFrameCount {
            setState(.dead)
        }
    }

    private func playShotSound() {
        let sfx = type == 0 ? Res.SFX_DISPARO_PATRICIO : Res.SFX_DISPARO_INGLES
        Sound.shared.play(id: sfx, loop: 0)
    }

    // MARK: - Healing

    private func updateHealingState() {
        recoveryTicks += 1
        if recoveryTicks >= ticksPerRecovery {
            recoveryTicks = 0
            health = min(health + recoveryPoints, resistancePoints)
        }
        if health >= resistancePoints {
            setState(.idle)
        }
    }

    // MARK: - Loadingr desde CSV

    /// Reads the unit stats (speed, health, attack, etc.) from the CSV data file for the given unit type id.
    /// - Parameter id: The index into the resource manager's unit paths array.
    func readUnit(_ id: Int) {
        let paths = ResourceManager.shared.unitPaths
        guard id >= 0, id < paths.count, let path = paths[id],
              let contenido = try? String(contentsOfFile: path, encoding: .utf8) else {
            Log.shared.error("Unit: failed to read unit with id=\(id)")
            return
        }

        type = id

        for line in contenido.components(separatedBy: .newlines) {
            let partes = line.components(separatedBy: ";")
            guard partes.count >= 2 else { continue }
            let clave = partes[0].trimmingCharacters(in: .whitespaces)
            let value = partes[1].trimmingCharacters(in: .whitespaces)

            switch clave {
            case "Sprite":
                let spriteIdx = value == "patricio" ? Res.SPR_PATRICIO : Res.SPR_INGLES
                firstSprite = 0  // animaciones comienzan en 0 dentro del sprite
                let sprs = ResourceManager.shared.sprites
                if spriteIdx >= 0, spriteIdx < sprs.count, let spr = sprs[spriteIdx] {
                    sprite = Sprite(copia: spr)
                }
            case "Velocidad":
                let v = Int(value) ?? 2
                currentSpeed = (v, v)
                defaultSpeedVec = (v, v)
            case "Puntos_Resistencia":
                let pr = Int(value) ?? 100
                resistancePoints = pr
                health = pr
            case "Puntos_Ataque":
                attackPoints = Int(value) ?? 10
            case "Visibilidad":
                visibility = Int(value) ?? 10
            case "Punteria":
                aim = Int(value) ?? 5
            case "Alcance_Tiro":
                attackRange = Int(value) ?? 5
            case "Intervalo_Entre_Ataques":
                attackInterval = Int(value) ?? 30
            case "Nombre":
                name = value
            case "Avatar":
                avatar = ResourceManager.shared.getImage(value)
            case "Puntos_De_Recuperacion":
                recoveryPoints = Int(value) ?? 20
            case "Ticks_Entre_Recuparacion":
                ticksPerRecovery = Int(value) ?? 50
            default:
                break
            }
        }
    }

    // MARK: - Check objective order

    private func checkOrderCompleted() {
        guard let ord = objectiveCommand else { return }
        if ord.id == .move || ord.id == .takeObject {
            if completedMoveObjective() {
                completedOrder = true
            }
        }
    }
}

// MARK: - Safe subscript helper
private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
