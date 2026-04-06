//
//  Unit.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Unidad.cs (multiple partial files merged) — represents a unit in the game.
//

import Foundation

class Unit: MapObject {

    // MARK: - Constants
    static let MAX_VISIBILITY = 15
    static let COLLISION_CHECK_DISTANCE = 4

    private let PATROL_RANDOM_MAX = 16
    private let PATROL_RANDOM_MIN = 8
    private let CANTIDAD_MINIMA_TILES_ORD_MOVER = 3
    private let SELECCION_ANCHO = 20
    private let SELECCION_Y = -3
    private let CUENTA_FRAME_MUERTO = 150

    // MARK: - Enums
    enum STATE {
        case IDLE, MOVING, DYING, ATACANDO, PURSUING_UNIT, DEAD, PATROLLING, HEALING
    }

    enum SUBESTADO {
        case INCREMENTAR_PASO, ESQUIVAR_UNIDAD, ALCANZAR_PASO, TERMINO_DE_DAR_PASO
    }

    // MARK: - Attributes
    private var type: Int = 0
    private var substate: SUBESTADO = .INCREMENTAR_PASO
    var faction: Episode.BANDO = .ENEMY
    private(set) var unitToEvade: Unit?
    private(set) var health: Int = 100
    private(set) var resistancePoints: Int = 100
    private(set) var attackPoints: Int = 10
    private(set) var visibility: Int = 10
    private(set) var aim: Int = 5
    private var attackRange: Int = 5
    private(set) var attackInterval: Int = 30
    private var currentSpeed: (x: Int, y: Int) = (2, 2)
    private var defaultSpeedVec: (x: Int, y: Int) = (2, 2)
    private var enemy: Unit?
    private var stateValue: STATE = .IDLE
    private var nextStateValue: STATE = .IDLE
    private var direction: Int = 0  // 0=N, 1=NE, 2=E, 3=SE, 4=S, 5=SO, 6=O, 7=NO
    private(set) var pathToFollow: [(i: Int, j: Int)]? = nil
    private(set) var nextTile: (x: Int, y: Int) = (0, 0)
    private var nextStep: (x: Int, y: Int) = (0, 0)
    var isSelected: Bool = false
    private var mode: Int = 0
    private var sprite: Sprite?
    private var count: Int = 0
    private var targetPos: (x: Int, y: Int) = (-1, -1)
    private(set) var name: String = ""
    private(set) var avatar: Surface?
    private var command: Command?
    private var objectiveCommand: Command?
    private(set) var completedOrder: Bool = false
    private var patrolPosition: (x: Int, y: Int) = (0, 0)
    private var desiredPosition: (x: Int, y: Int) = (0, 0)  // offset en formación
    private var firstSprite: Int = 0
    private var ticksPerRecovery: Int = 50
    private var recoveryPoints: Int = 20
    private var recoveryTicks: Int = 0
    private var isCommander: Bool = false
    private var group: Group?
    private var completedObjectiveOrder: Bool = false

    // Continuous world position for smooth movement
    private var posX: Double = 0
    private var posY: Double = 0

    // MARK: - Public properties

    var currentState: STATE { stateValue }

    var range: Int { attackRange }
    var speed: (x: Int, y: Int) { currentSpeed }
    var defaultSpeed: Int { defaultSpeedVec.x }
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
            Log.shared.debug("La copia de la unit no esta cargada: id=\(id)")
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
        guard stateValue != .DEAD else { return false }

        var movedOnMap = false
        completedOrder = false

        switch stateValue {
        case .IDLE:
            updateIdleAnimation()
        case .MOVING:
            movedOnMap = updateMovingState()
        case .PATROLLING:
            movedOnMap = updatePatrollingState()
        case .PURSUING_UNIT:
            updatePursuingUnitState()
        case .ATACANDO:
            updateAttackingState()
        case .DYING:
            updateDyingState()
        case .DEAD:
            break
        case .HEALING:
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
            let barAncho = Int(Double(SELECCION_ANCHO) * healthFraction)
            g.setColor(Definitions.COLOR_GREEN)
            g.fillRect(x - SELECCION_ANCHO / 2,
                               y + SELECCION_Y,
                               barAncho, 3)
            g.setColor(Definitions.COLOR_RED)
            g.fillRect(x - SELECCION_ANCHO / 2 + barAncho,
                               y + SELECCION_Y,
                               SELECCION_ANCHO - barAncho, 3)
        }
        sprite?.draw(g, x - (sprite?.frameAncho ?? 0) / 2,
                           y - (sprite?.frameAlto ?? 0))
    }

    // MARK: - Public orders

    func move(_ x: Int, _ y: Int) {
        command = Command(.MOVE, x, y)
        setState(.MOVING)
        nextStateValue = .IDLE

        let path = PathFinder.instance.findShortestPath(
            physicalTilePos.x, physicalTilePos.y, x, y)

        if let c = path, !c.isEmpty {
            // First element is destination, last is origin. Used as a stack (popLast = next step).
            pathToFollow = Array(c.dropLast())   // quita el nodo start (último = origen)
        } else {
            setState(.IDLE)
            pathToFollow = nil
            return
        }

        substate = .INCREMENTAR_PASO
    }

    func patrol() {
        setState(.PATROLLING)
        nextStateValue = .PATROLLING
        patrolPosition = physicalTilePos
        pathToFollow = findRandomPatrolPath(
            physicalTilePos.x, physicalTilePos.y)
    }

    func attack(_ enemy: Unit) {
        self.enemy = enemy
        targetPos = (-1, -1)
        setState(.PURSUING_UNIT)
    }

    func stop() {
        setState(.IDLE)
        pathToFollow = nil
    }

    func setObjectiveCommand(_ ord: Command?) {
        completedOrder = false
        objectiveCommand = ord
    }

    func recoverHealth() {
        setState(.HEALING)
    }

    // MARK: - Collision and evasion

    func hasCollision(_ other: Unit) -> Bool {
        let dx = abs(physicalTilePos.x - other.physicalTilePos.x)
        let dy = abs(physicalTilePos.y - other.physicalTilePos.y)
        return dx < 2 && dy < 2
    }

    func evadeUnit(_ other: Unit, _ visible: [Unit]?) {
        unitToEvade = other
        substate = .ESQUIVAR_UNIDAD
    }

    // MARK: - Queries

    func isDead() -> Bool { stateValue == .DEAD || stateValue == .DYING }

    func isMoving() -> Bool {
        return stateValue == .MOVING || stateValue == .PATROLLING || stateValue == .PURSUING_UNIT
    }

    func isOnScreen() -> Bool {
        guard let cam = MapObject.camera else { return false }
        return x >= cam.startX && x <= cam.startX + cam.width &&
               y >= cam.startY && y <= cam.startY + cam.height
    }

    func calculateDistance(_ toI: Int, _ toJ: Int) -> Double {
        let di = Double(physicalTilePos.x - toI)
        let dj = Double(physicalTilePos.y - toJ)
        return sqrt(di * di + dj * dj)
    }

    func completedMoveObjective() -> Bool {
        guard let ord = objectiveCommand else { return false }
        let dist = calculateDistance(ord.point.x, ord.point.y)
        return dist <= Double(CANTIDAD_MINIMA_TILES_ORD_MOVER)
    }

    // MARK: - Group / formation

    var belongsToGroup: Bool { group != nil }
    var myGroup: Group? { group }

    func joinGroup(_ group: Group) {
        self.group = group
    }

    func leaveGroup() {
        group = nil
    }

    func markAsCommander() {
        isCommander = true
    }

    func unmarkCommander() {
        isCommander = false
    }

    func calculatePathAtDistance(_ commanderPath: [(i: Int, j: Int)],
                                  _ offsetX: Int, _ offsetY: Int) {
        guard let map = MapObject.map else { return }

        setState(.MOVING)
        nextStateValue = .IDLE

        // Build offset copy of commander's path.
        // commanderPath: [0]=destination, [last]=first step (Swift format).
        // Iterate reversed so pathCopy[0]=first step, ..., [last]=destination (same order as C# Stack).
        let pathCopy: [(i: Int, j: Int)] = commanderPath.reversed().map { (i: $0.i + offsetX, j: $0.j + offsetY) }

        var pathList: [(i: Int, j: Int)] = []
        var idx = 0

        while idx < pathCopy.count {
            let point = pathCopy[idx]
            if !map.isWalkable(point.i, point.j) {
                if idx > 0 {
                    let prevIdx = idx - 1
                    guard let nextValidIdx = findNextValidPosition(pathCopy, from: idx) else {
                        // No more valid points ahead — stop here
                        idx = pathCopy.count
                        continue
                    }
                    idx = nextValidIdx

                    var newPath = PathFinder.instance.findShortestPath(
                        pathCopy[prevIdx].i, pathCopy[prevIdx].j,
                        pathCopy[idx].i,      pathCopy[idx].j)

                    if newPath == nil {
                        guard let prevValidIdx = findPrevValidPosition(pathCopy, from: nextValidIdx) else {
                            Log.shared.debug("El path no es valido por ningun lado.")
                            pathToFollow = []
                            return
                        }
                        idx = prevValidIdx
                        newPath = PathFinder.instance.findShortestPath(
                            pathCopy[prevIdx].i, pathCopy[prevIdx].j,
                            pathCopy[idx].i,      pathCopy[idx].j)
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
        substate = .INCREMENTAR_PASO
    }

    private func findNextValidPosition(_ list: [(i: Int, j: Int)], from start: Int) -> Int? {
        guard let map = MapObject.map else { return nil }
        var idx = start
        while idx < list.count, !map.isWalkable(list[idx].i, list[idx].j) {
            idx += 1
        }
        if idx >= list.count { return nil }
        // Skip up to two extra steps, same as C# logic
        if idx < list.count - 1 {
            let next = list[idx + 1]
            if map.isWalkable(next.i, next.j) {
                idx += 1
                if idx < list.count - 1 {
                    let next2 = list[idx + 1]
                    if map.isWalkable(next2.i, next2.j) {
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
        while idx >= 0, !map.isWalkable(list[idx].i, list[idx].j) {
            idx -= 1
        }
        if idx < 0 { return nil }
        return idx
    }

    func isUnderMouse() -> Bool {
        let mx = Int(Mouse.shared.X)
        let my = Int(Mouse.shared.Y)
        let fw = sprite?.frameAncho ?? (frameWidth > 0 ? frameWidth : 20)
        let fh = sprite?.frameAlto  ?? (frameHeight  > 0 ? frameHeight  : 30)
        let hw = fw / 2
        return mx >= x - hw && mx <= x + hw && my >= y - fh && my <= y
    }

    func heal(_ x: Int, _ y: Int) {
        command = Command(.HEAL, x, y)

        guard let map = MapObject.map else { return }
        let p = map.getLineOfSightPosition(x, physicalTilePos.x, y, physicalTilePos.y)
        if p.x == -1 {
            Log.shared.debug("No se la puede mandar a heal.")
            return
        }
        setHealing(p.x, p.y)
    }

    private func setHealing(_ x: Int, _ y: Int) {
        setState(.MOVING)
        nextStateValue = .HEALING

        let path = PathFinder.instance.findShortestPath(
            physicalTilePos.x, physicalTilePos.y, x, y)

        if let c = path, !c.isEmpty {
            pathToFollow = Array(c.dropLast())
        } else {
            Log.shared.debug("No se encontro el path para heal...")
            setState(.IDLE)
            pathToFollow = nil
            return
        }
        substate = .INCREMENTAR_PASO
    }

    // MARK: - Selección por arrastre de mouse (rectangle)
    func selectIfInRect(_ x: Int, _ y: Int, _ w: Int, _ h: Int) -> Bool {
        let fw = sprite?.frameAncho ?? (frameWidth > 0 ? frameWidth : 20)
        let fh = sprite?.frameAlto  ?? (frameHeight  > 0 ? frameHeight  : 30)
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

    private func setState(_ e: STATE) {
        stateValue = e
        count = 0
        if e == .IDLE {
            pathToFollow = nil
        }
        if e == .ATACANDO {
            enemy?.counterAttack(self)
        }
    }

    /// Called when this unit starts being attacked. If idle and in range, counter-attacks.
    func counterAttack(_ attacker: Unit) {
        guard stateValue == .IDLE else { return }
        Log.shared.debug("Me atacan, contraataco.")
        enemy = attacker
        if calculateDistance(attacker.physicalTilePos.x, attacker.physicalTilePos.y) < Double(attackRange) {
            aimAtUnit(attacker)
            setState(.ATACANDO)
        }
    }

    private func updateIdleAnimation() {
        sprite?.update()
        let anim = firstAnimation() + direction
        sprite?.setAnimation(anim)
        sprite?.play()
    }

    private func dibujarSpriteActual() {
        sprite?.update()
    }

    private func firstAnimation() -> Int {
        switch stateValue {
        case .IDLE, .HEALING:
            return type == 0 ? Res.SPR_ANIM_PATRICIO_QUIETO_N : Res.SPR_ANIM_INGLES_QUIETO_N
        case .MOVING, .PURSUING_UNIT, .PATROLLING:
            return type == 0 ? Res.SPR_ANIM_PATRICIO_CAMINA_N : Res.SPR_ANIM_INGLES_CAMINA_N
        case .DYING, .DEAD:
            return type == 0 ? Res.SPR_ANIM_PATRICIO_MUERE_N : Res.SPR_ANIM_INGLES_MUERE_N
        case .ATACANDO:
            return type == 0 ? Res.SPR_ANIM_PATRICIO_ATACA_N : Res.SPR_ANIM_INGLES_ATACA_N
        }
    }

    // MARK: - Movement

    private func updateMovingState() -> Bool {
        return moverse()
    }

    private func updatePatrollingState() -> Bool {
        if pathToFollow == nil {
            pathToFollow = findRandomPatrolPath(physicalTilePos.x, physicalTilePos.y)
        }
        return moverse()
    }

    private func moverse() -> Bool {
        switch substate {
        case .INCREMENTAR_PASO:
            guard let path = pathToFollow, !path.isEmpty else {
                setState(nextStateValue)
                pathToFollow = nil
                return false
            }
            nextTile = (path.last!.i, path.last!.j)
            pathToFollow!.removeLast()
            nextStep = tileToWorld(nextTile.x, nextTile.y)
            substate = .ALCANZAR_PASO

        case .ESQUIVAR_UNIDAD:
            recalculateNextStep()
            substate = .ALCANZAR_PASO
            return true

        default: break
        }

        let dir = getDirection(nextStep.x, nextStep.y)
        if dir != -1 { direction = dir }

        // Update walking animation
        let anim = firstAnimation() + direction
        sprite?.setAnimation(anim)
        sprite?.play()

        let arrived = moveToNextStep()

        if arrived {
            let prevTile = physicalTilePos
            previousTile = prevTile
            physicalTilePos = nextTile
            substate = .INCREMENTAR_PASO
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
        worldPos = tileToWorld(physicalTilePos.x, physicalTilePos.y)
        unitToEvade = nil

        guard pathToFollow != nil, !pathToFollow!.isEmpty else {
            setLastPosition()
            return
        }

        // Pop the tile we were heading to (now blocked) and find a detour.
        var nextTileIJ = pathToFollow!.removeLast()

        var newPath = PathFinder.instance.findShortestPath(
            physicalTilePos.x, physicalTilePos.y,
            nextTileIJ.i, nextTileIJ.j)

        // If no path, keep popping further waypoints until one is reachable.
        while newPath == nil {
            guard pathToFollow != nil, !pathToFollow!.isEmpty else {
                Log.shared.debug("RecalcularProximoPaso: sin path alternativo.")
                setLastPosition()
                return
            }
            nextTileIJ = pathToFollow!.removeLast()
            newPath = PathFinder.instance.findShortestPath(
                physicalTilePos.x, physicalTilePos.y,
                nextTileIJ.i, nextTileIJ.j)
        }

        // newPath: [last] = first step toward nextTileIJ, [0] = nextTileIJ.
        var detour = newPath!
        let primerPaso = detour.removeLast()          // consume first step
        nextTile = (primerPaso.i, primerPaso.j)
        nextStep = tileToWorld(nextTile.x, nextTile.y)

        // Prepend remaining detour steps before the original remaining path
        // (equivalent to PathFinder.AdherirCamino in C#).
        pathToFollow = (pathToFollow ?? []) + detour
    }

    private func setLastPosition() {
        nextTile = physicalTilePos
        nextStep = tileToWorld(nextTile.x, nextTile.y)
    }

    private func getDirection(_ targetX: Int, _ targetY: Int) -> Int {
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

    private func findRandomPatrolPath(_ i: Int, _ j: Int) -> [(i: Int, j: Int)]? {
        guard let map = MapObject.map else { return nil }
        let range = PATROL_RANDOM_MAX - PATROL_RANDOM_MIN
        // Mirror original C#: loop until a valid path is found.
        // Use the stored patrol base position as the destination origin (not current pos).
        var path: [(i: Int, j: Int)]? = nil
        var intentos = 0
        while path == nil && intentos < 20 {
            intentos += 1
            let offI = Int.random(in: 0..<range) + PATROL_RANDOM_MIN
            let offJ = Int.random(in: 0..<range) + PATROL_RANDOM_MIN
            let signoI = Bool.random() ? 1 : -1
            let signoJ = Bool.random() ? 1 : -1
            let destI = patrolPosition.x + signoI * offI
            let destJ = patrolPosition.y + signoJ * offJ
            guard map.isWalkable(destI, destJ) else { continue }
            path = PathFinder.instance.findShortestPath(i, j, destI, destJ)
        }
        return path
    }

    // MARK: - Pursuit and attack

    private func updatePursuingUnitState() {
        guard let enemy = enemy else {
            setState(.IDLE)
            return
        }
        if enemy.isDead() {
            self.enemy = nil
            setState(.IDLE)
            return
        }

        let dist = calculateDistance(enemy.physicalTilePos.x, enemy.physicalTilePos.y)

        if dist <= Double(attackRange) {
            // In range: attack
            aimAtUnit(enemy)
            setState(.ATACANDO)
        } else {
            // Move closer
            if pathToFollow == nil || targetPos != enemy.physicalTilePos {
                targetPos = enemy.physicalTilePos
                move(enemy.physicalTilePos.x, enemy.physicalTilePos.y)
            } else {
                _ = moverse()
            }
        }

        let anim = firstAnimation() + direction
        sprite?.setAnimation(anim)
        sprite?.play()
    }

    private func updateAttackingState() {
        guard let enemy = enemy else {
            setState(.IDLE)
            return
        }
        if enemy.isDead() {
            self.enemy = nil
            setState(.IDLE)
            return
        }

        count += 1
        let anim = firstAnimation() + direction
        sprite?.setAnimation(anim)
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
        let dist = calculateDistance(enemy.physicalTilePos.x, enemy.physicalTilePos.y)
        if dist > Double(attackRange) {
            setState(.PURSUING_UNIT)
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

    func takeDamage(_ danio: Int) {
        health -= danio
        if health <= 0 {
            health = 0
            morir()
        }
    }

    func morir() {
        Log.shared.debug("Me mori.")
        setState(.DYING)
        enemy = nil
        if type == Res.UNIDAD_PATRICIO {
            Sound.shared.play(Res.SFX_MUERTE_PATRICIO, 0)
        }
    }

    private func updateDyingState() {
        if count == 0 {
            let anim = firstAnimation() + direction
            sprite?.setAnimation(anim)
            sprite?.loop = false
            sprite?.play()
        }

        if sprite?.isAnimationDone() == true {
            sprite?.setFrame(sprite!.frameCount - 1)
            sprite?.stop()
        }

        count += 1
        if count >= CUENTA_FRAME_MUERTO {
            setState(.DEAD)
        }
    }

    private func playShotSound() {
        let sfx = type == 0 ? Res.SFX_DISPARO_PATRICIO : Res.SFX_DISPARO_INGLES
        Sound.shared.play(sfx, 0)
    }

    // MARK: - Healing

    private func updateHealingState() {
        recoveryTicks += 1
        if recoveryTicks >= ticksPerRecovery {
            recoveryTicks = 0
            health = min(health + recoveryPoints, resistancePoints)
        }
        if health >= resistancePoints {
            setState(.IDLE)
        }
    }

    // MARK: - Loadingr desde CSV

    /// Reads the unit attributes from the CSV file at the path indexed by `id`.
    func readUnit(_ id: Int) {
        let paths = ResourceManager.shared.unitPaths
        guard id >= 0, id < paths.count, let path = paths[id],
              let contenido = try? String(contentsOfFile: path, encoding: .utf8) else {
            Log.shared.error("No se puede leer la unit con id=\(id)")
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
        if ord.id == .MOVE || ord.id == .TAKE_OBJECT {
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
