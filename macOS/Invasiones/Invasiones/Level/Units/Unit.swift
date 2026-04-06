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
    static let MAX_VISIBILITY            = 15
    static let COLLISION_CHECK_DISTANCE = 4

    private let PATROL_RANDOM_MAX = 16
    private let PATROL_RANDOM_MIN = 8
    private let CANTIDAD_MINIMA_TILES_ORD_MOVER = 3
    private let SELECCION_ANCHO   = 20
    private let SELECCION_Y       = -3
    private let CUENTA_FRAME_MUERTO = 150

    // MARK: - Enums
    enum STATE {
        case IDLE, MOVING, DYING, ATACANDO, PURSUING_UNIT, DEAD, PATROLLING, HEALING
    }

    enum SUBESTADO {
        case INCREMENTAR_PASO, ESQUIVAR_UNIDAD, ALCANZAR_PASO, TERMINO_DE_DAR_PASO
    }

    // MARK: - Attributes
    private var m_type:                   Int = 0
    private var m_substate:              SUBESTADO = .INCREMENTAR_PASO
    private var m_faction:                  Episode.BANDO = .ENEMY
    private var m_unitToEvade:        Unit?
    private var m_health:                  Int = 100
    private var m_resistancePoints:    Int = 100
    private var m_attackPoints:         Int = 10
    private var m_visibility:            Int = 10
    private var m_aim:               Int = 5
    private var m_attackRange:          Int = 5
    private var m_attackInterval:  Int = 30
    private var m_currentSpeed:        (x: Int, y: Int) = (2, 2)
    private var m_defaultSpeed:    (x: Int, y: Int) = (2, 2)
    private var m_enemy:               Unit?
    private var m_state:                STATE = .IDLE
    private var m_nextState:         STATE = .IDLE
    private var m_direction:             Int = 0  // 0=N, 1=NE, 2=E, 3=SE, 4=S, 5=SO, 6=O, 7=NO
    private var m_pathToFollow:         [(i: Int, j: Int)]? = nil
    private var m_nextTile:           (x: Int, y: Int) = (0, 0)
    private var m_nextStep:           (x: Int, y: Int) = (0, 0)
    private var m_selected:          Bool = false
    private var m_mode:                  Int = 0
    private var m_sprite:                Sprite?
    private var m_count:                Int = 0
    private var m_targetPos:                (x: Int, y: Int) = (-1, -1)
    private var m_name:                String = ""
    private var m_avatar:                Surface?
    private var m_command:                 Command?
    private var m_objectiveCommand:       Command?
    private var m_completedOrder:     Bool = false
    private var m_patrolPosition:    (x: Int, y: Int) = (0, 0)
    private var m_desiredPosition:       (x: Int, y: Int) = (0, 0)  // offset en formación
    private var m_firstSprite:          Int = 0
    private var m_ticksPerRecovery: Int = 50
    private var m_recoveryPoints:  Int = 20
    private var m_recoveryTicks:    Int = 0
    private var m_isCommander:          Bool = false
    private var m_group:                 Group?
    private var m_completedObjectiveOrder: Bool = false

    // Continuous world position for smooth movement
    private var m_posX:   Double = 0
    private var m_posY:   Double = 0

    // MARK: - Public properties

    var faction: Episode.BANDO {
        get { m_faction }
        set { m_faction = newValue }
    }

    var currentState: STATE { m_state }

    var isSelected: Bool {
        get { m_selected }
        set { m_selected = newValue }
    }

    var attackPoints:     Int { m_attackPoints     }
    var health:              Int { m_health               }
    var resistancePoints:Int { m_resistancePoints }
    var range:            Int { m_attackRange        }
    var visibility:        Int { m_visibility          }
    var speed:          (x: Int, y: Int) { m_currentSpeed }
    var defaultSpeed:Int { m_defaultSpeed.x }
    var attackInterval: Int { m_attackInterval }
    var aim:           Int { m_aim }
    var avatar:             Surface? { m_avatar }
    var name:             String { m_name }
    var completedOrder:       Bool { m_completedOrder }
    var nextTile:        (x: Int, y: Int) { m_nextTile }
    var formationOffset:  (x: Int, y: Int) {
        get { m_desiredPosition }
        set { m_desiredPosition = newValue }
    }
    var unitToEvade: Unit? { m_unitToEvade }
    var pathToFollow: [(i: Int, j: Int)]? { m_pathToFollow }

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
        m_type                    = copia.m_type
        m_currentSpeed         = copia.m_currentSpeed
        m_defaultSpeed     = copia.m_currentSpeed
        m_health                   = copia.m_resistancePoints
        m_resistancePoints     = copia.m_resistancePoints
        m_attackPoints          = copia.m_attackPoints
        m_visibility             = copia.m_visibility
        m_aim                = copia.m_aim
        m_attackRange           = copia.m_attackRange
        m_attackInterval   = copia.m_attackInterval
        m_avatar                  = copia.m_avatar
        m_name                  = copia.m_name
        m_ticksPerRecovery = copia.m_ticksPerRecovery
        m_recoveryPoints    = copia.m_recoveryPoints

        // Clone sprite
        if let s = copia.m_sprite {
            m_sprite = Sprite(copia: s)
        }
    }

    // MARK: - Main update

    /// Updates the unit. Returns true if it moved on the physical map.
    @discardableResult
    override func update() -> Bool {
        guard m_state != .DEAD else { return false }

        var movedOnMap = false
        m_completedOrder = false

        switch m_state {
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
        if m_selected {
            let healthFraction = Double(m_health) / Double(max(m_resistancePoints, 1))
            let barAncho = Int(Double(SELECCION_ANCHO) * healthFraction)
            g.setColor(Definitions.COLOR_GREEN)
            g.fillRect(m_x - SELECCION_ANCHO / 2,
                               m_y + SELECCION_Y,
                               barAncho, 3)
            g.setColor(Definitions.COLOR_RED)
            g.fillRect(m_x - SELECCION_ANCHO / 2 + barAncho,
                               m_y + SELECCION_Y,
                               SELECCION_ANCHO - barAncho, 3)
        }
        m_sprite?.draw(g, m_x - (m_sprite?.frameAncho ?? 0) / 2,
                           m_y - (m_sprite?.frameAlto ?? 0))
    }

    // MARK: - Public orders

    func move(_ x: Int, _ y: Int) {
        m_command = Command(.MOVE, x, y)
        setState(.MOVING)
        m_nextState = .IDLE

        let path = PathFinder.instance.findShortestPath(
            m_physicalTilePos.x, m_physicalTilePos.y, x, y)

        if let c = path, !c.isEmpty {
            // First element is destination, last is origin. Used as a stack (popLast = next step).
            m_pathToFollow = Array(c.dropLast())   // quita el nodo start (último = origen)
        } else {
            setState(.IDLE)
            m_pathToFollow = nil
            return
        }

        m_substate = .INCREMENTAR_PASO
    }

    func patrol() {
        setState(.PATROLLING)
        m_nextState = .PATROLLING
        m_patrolPosition = m_physicalTilePos
        m_pathToFollow = findRandomPatrolPath(
            m_physicalTilePos.x, m_physicalTilePos.y)
    }

    func attack(_ enemy: Unit) {
        m_enemy = enemy
        m_targetPos  = (-1, -1)
        setState(.PURSUING_UNIT)
    }

    func stop() {
        setState(.IDLE)
        m_pathToFollow = nil
    }

    func setObjectiveCommand(_ ord: Command?) {
        m_completedOrder = false
        m_objectiveCommand   = ord
    }

    func recoverHealth() {
        setState(.HEALING)
    }

    // MARK: - Collision and evasion

    func hasCollision(_ other: Unit) -> Bool {
        let dx = abs(m_physicalTilePos.x - other.m_physicalTilePos.x)
        let dy = abs(m_physicalTilePos.y - other.m_physicalTilePos.y)
        return dx < 2 && dy < 2
    }

    func evadeUnit(_ other: Unit, _ visible: [Unit]?) {
        m_unitToEvade = other
        m_substate       = .ESQUIVAR_UNIDAD
    }

    // MARK: - Queries

    func isDead() -> Bool { m_state == .DEAD || m_state == .DYING }

    func isMoving() -> Bool {
        return m_state == .MOVING || m_state == .PATROLLING || m_state == .PURSUING_UNIT
    }

    func isOnScreen() -> Bool {
        guard let cam = MapObject.camera else { return false }
        return m_x >= cam.startX && m_x <= cam.startX + cam.width &&
               m_y >= cam.startY && m_y <= cam.startY + cam.height
    }

    func calculateDistance(_ toI: Int, _ toJ: Int) -> Double {
        let di = Double(m_physicalTilePos.x - toI)
        let dj = Double(m_physicalTilePos.y - toJ)
        return sqrt(di * di + dj * dj)
    }

    func completedMoveObjective() -> Bool {
        guard let ord = m_objectiveCommand else { return false }
        let dist = calculateDistance(ord.point.x, ord.point.y)
        return dist <= Double(CANTIDAD_MINIMA_TILES_ORD_MOVER)
    }

    // MARK: - Group / formation

    var belongsToGroup: Bool { m_group != nil }
    var myGroup: Group? { m_group }

    func joinGroup(_ group: Group) {
        m_group = group
    }

    func leaveGroup() {
        m_group = nil
    }

    func markAsCommander() {
        m_isCommander = true
    }

    func unmarkCommander() {
        m_isCommander = false
    }

    func calculatePathAtDistance(_ commanderPath: [(i: Int, j: Int)],
                                  _ offsetX: Int, _ offsetY: Int) {
        guard let map = MapObject.map else { return }

        setState(.MOVING)
        m_nextState = .IDLE

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
                            m_pathToFollow = []
                            return
                        }
                        idx = prevValidIdx
                        newPath = PathFinder.instance.findShortestPath(
                            pathCopy[prevIdx].i, pathCopy[prevIdx].j,
                            pathCopy[idx].i,      pathCopy[idx].j)
                    }

                    guard let segment = newPath else {
                        m_pathToFollow = []
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
        m_pathToFollow = pathList.reversed()
        m_substate = .INCREMENTAR_PASO
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
        let fw = m_sprite?.frameAncho ?? (m_frameWidth > 0 ? m_frameWidth : 20)
        let fh = m_sprite?.frameAlto  ?? (m_frameHeight  > 0 ? m_frameHeight  : 30)
        let hw = fw / 2
        return mx >= m_x - hw && mx <= m_x + hw && my >= m_y - fh && my <= m_y
    }

    func heal(_ x: Int, _ y: Int) {
        m_command = Command(.HEAL, x, y)

        guard let map = MapObject.map else { return }
        let p = map.getLineOfSightPosition(x, m_physicalTilePos.x, y, m_physicalTilePos.y)
        if p.x == -1 {
            Log.shared.debug("No se la puede mandar a heal.")
            return
        }
        setHealing(p.x, p.y)
    }

    private func setHealing(_ x: Int, _ y: Int) {
        setState(.MOVING)
        m_nextState = .HEALING

        let path = PathFinder.instance.findShortestPath(
            m_physicalTilePos.x, m_physicalTilePos.y, x, y)

        if let c = path, !c.isEmpty {
            m_pathToFollow = Array(c.dropLast())
        } else {
            Log.shared.debug("No se encontro el path para heal...")
            setState(.IDLE)
            m_pathToFollow = nil
            return
        }
        m_substate = .INCREMENTAR_PASO
    }

    // MARK: - Selección por arrastre de mouse (rectangle)
    func selectIfInRect(_ x: Int, _ y: Int, _ w: Int, _ h: Int) -> Bool {
        let fw = m_sprite?.frameAncho ?? (m_frameWidth > 0 ? m_frameWidth : 20)
        let fh = m_sprite?.frameAlto  ?? (m_frameHeight  > 0 ? m_frameHeight  : 30)
        // In Swift, m_x = sprite horizontal center, m_y = sprite bottom.
        // Sprite bounds: left = m_x-fw/2, right = m_x+fw/2, top = m_y-fh, bottom = m_y.
        // Matches the original C# check (translated from top-left convention to center/bottom).
        let inRange = x <= m_x - fw / 2
                  && y <= m_y - fh / 2
                  && x + w > m_x + fw / 2
                  && y + h > m_y
        if inRange { m_selected = true }
        return inRange
    }

    // MARK: - Private

    private func setState(_ e: STATE) {
        m_state = e
        m_count = 0
        if e == .IDLE {
            m_pathToFollow = nil
        }
        if e == .ATACANDO {
            m_enemy?.counterAttack(self)
        }
    }

    /// Called when this unit starts being attacked. If idle and in range, counter-attacks.
    func counterAttack(_ attacker: Unit) {
        guard m_state == .IDLE else { return }
        Log.shared.debug("Me atacan, contraataco.")
        m_enemy = attacker
        if calculateDistance(attacker.m_physicalTilePos.x, attacker.m_physicalTilePos.y) < Double(m_attackRange) {
            aimAtUnit(attacker)
            setState(.ATACANDO)
        }
    }

    private func updateIdleAnimation() {
        m_sprite?.update()
        let anim = firstAnimation() + m_direction
        m_sprite?.setAnimation(anim)
        m_sprite?.play()
    }

    private func dibujarSpriteActual() {
        m_sprite?.update()
    }

    private func firstAnimation() -> Int {
        switch m_state {
        case .IDLE, .HEALING:
            return m_type == 0 ? Res.SPR_ANIM_PATRICIO_QUIETO_N : Res.SPR_ANIM_INGLES_QUIETO_N
        case .MOVING, .PURSUING_UNIT, .PATROLLING:
            return m_type == 0 ? Res.SPR_ANIM_PATRICIO_CAMINA_N : Res.SPR_ANIM_INGLES_CAMINA_N
        case .DYING, .DEAD:
            return m_type == 0 ? Res.SPR_ANIM_PATRICIO_MUERE_N : Res.SPR_ANIM_INGLES_MUERE_N
        case .ATACANDO:
            return m_type == 0 ? Res.SPR_ANIM_PATRICIO_ATACA_N : Res.SPR_ANIM_INGLES_ATACA_N
        }
    }

    // MARK: - Movement

    private func updateMovingState() -> Bool {
        return moverse()
    }

    private func updatePatrollingState() -> Bool {
        if m_pathToFollow == nil {
            m_pathToFollow = findRandomPatrolPath(m_physicalTilePos.x, m_physicalTilePos.y)
        }
        return moverse()
    }

    private func moverse() -> Bool {
        switch m_substate {
        case .INCREMENTAR_PASO:
            guard let path = m_pathToFollow, !path.isEmpty else {
                setState(m_nextState)
                m_pathToFollow = nil
                return false
            }
            m_nextTile = (path.last!.i, path.last!.j)
            m_pathToFollow!.removeLast()
            m_nextStep = tileToWorld(m_nextTile.x, m_nextTile.y)
            m_substate   = .ALCANZAR_PASO

        case .ESQUIVAR_UNIDAD:
            recalculateNextStep()
            m_substate = .ALCANZAR_PASO
            return true

        default: break
        }

        let dir = getDirection(m_nextStep.x, m_nextStep.y)
        if dir != -1 { m_direction = dir }

        // Update walking animation
        let anim = firstAnimation() + m_direction
        m_sprite?.setAnimation(anim)
        m_sprite?.play()

        let arrived = moveToNextStep()

        if arrived {
            let prevTile = m_physicalTilePos
            m_previousTilePos = prevTile
            m_physicalTilePos   = m_nextTile
            m_substate         = .INCREMENTAR_PASO
            return true
        }
        return false
    }

    /// Moves one step toward m_nextStep using Euclidean normalization.
    /// Direction-based per-axis velocity (C# parity) is not used here because in the isometric
    /// coordinate system adjacent tiles have unequal dx/dy (e.g. SE tile: dx=+16, dy=+8),
    /// so applying equal vx/vy per direction overshoots the shorter axis and causes visual jitter.
    private func moveToNextStep() -> Bool {
        let spd = m_defaultSpeed.x

        let dx = m_nextStep.x - m_worldPos.x
        let dy = m_nextStep.y - m_worldPos.y
        let dist = sqrt(Double(dx * dx + dy * dy))

        if dist <= Double(spd) {
            m_worldPos = m_nextStep
            // Keep m_currentSpeed consistent for any callers that read it.
            m_currentSpeed = (dx, dy)
            return true
        }

        let ratio = Double(spd) / dist
        let vx = Int(Double(dx) * ratio)
        let vy = Int(Double(dy) * ratio)
        m_currentSpeed = (vx, vy)
        m_worldPos.x += vx
        m_worldPos.y += vy
        return false
    }

    private func recalculateNextStep() {
        // Snap back to the current tile (undo partial movement toward the blocked step).
        m_worldPos = tileToWorld(m_physicalTilePos.x, m_physicalTilePos.y)
        m_unitToEvade = nil

        guard m_pathToFollow != nil, !m_pathToFollow!.isEmpty else {
            setLastPosition()
            return
        }

        // Pop the tile we were heading to (now blocked) and find a detour.
        var nextTileIJ = m_pathToFollow!.removeLast()

        var newPath = PathFinder.instance.findShortestPath(
            m_physicalTilePos.x, m_physicalTilePos.y,
            nextTileIJ.i, nextTileIJ.j)

        // If no path, keep popping further waypoints until one is reachable.
        while newPath == nil {
            guard m_pathToFollow != nil, !m_pathToFollow!.isEmpty else {
                Log.shared.debug("RecalcularProximoPaso: sin path alternativo.")
                setLastPosition()
                return
            }
            nextTileIJ = m_pathToFollow!.removeLast()
            newPath = PathFinder.instance.findShortestPath(
                m_physicalTilePos.x, m_physicalTilePos.y,
                nextTileIJ.i, nextTileIJ.j)
        }

        // newPath: [last] = first step toward nextTileIJ, [0] = nextTileIJ.
        var detour = newPath!
        let primerPaso = detour.removeLast()          // consume first step
        m_nextTile = (primerPaso.i, primerPaso.j)
        m_nextStep = tileToWorld(m_nextTile.x, m_nextTile.y)

        // Prepend remaining detour steps before the original remaining path
        // (equivalent to PathFinder.AdherirCamino in C#).
        m_pathToFollow = (m_pathToFollow ?? []) + detour
    }

    private func setLastPosition() {
        m_nextTile = m_physicalTilePos
        m_nextStep = tileToWorld(m_nextTile.x, m_nextTile.y)
    }

    private func getDirection(_ targetX: Int, _ targetY: Int) -> Int {
        let dx = targetX - m_worldPos.x
        let dy = targetY - m_worldPos.y
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
            let offI  = Int.random(in: 0..<range) + PATROL_RANDOM_MIN
            let offJ  = Int.random(in: 0..<range) + PATROL_RANDOM_MIN
            let signoI = Bool.random() ? 1 : -1
            let signoJ = Bool.random() ? 1 : -1
            let destI = m_patrolPosition.x + signoI * offI
            let destJ = m_patrolPosition.y + signoJ * offJ
            guard map.isWalkable(destI, destJ) else { continue }
            path = PathFinder.instance.findShortestPath(i, j, destI, destJ)
        }
        return path
    }

    // MARK: - Pursuit and attack

    private func updatePursuingUnitState() {
        guard let enemy = m_enemy else {
            setState(.IDLE)
            return
        }
        if enemy.isDead() {
            m_enemy = nil
            setState(.IDLE)
            return
        }

        let dist = calculateDistance(enemy.m_physicalTilePos.x, enemy.m_physicalTilePos.y)

        if dist <= Double(m_attackRange) {
            // In range: attack
            aimAtUnit(enemy)
            setState(.ATACANDO)
        } else {
            // Move closer
            if m_pathToFollow == nil || m_targetPos != enemy.m_physicalTilePos {
                m_targetPos = enemy.m_physicalTilePos
                move(enemy.m_physicalTilePos.x, enemy.m_physicalTilePos.y)
            } else {
                _ = moverse()
            }
        }

        let anim = firstAnimation() + m_direction
        m_sprite?.setAnimation(anim)
        m_sprite?.play()
    }

    private func updateAttackingState() {
        guard let enemy = m_enemy else {
            setState(.IDLE)
            return
        }
        if enemy.isDead() {
            m_enemy = nil
            setState(.IDLE)
            return
        }

        m_count += 1
        let anim = firstAnimation() + m_direction
        m_sprite?.setAnimation(anim)
        m_sprite?.play()

        if m_count >= m_attackInterval {
            m_count = 0
            let hit = calculateDamage()
            if hit > 0 {
                enemy.takeDamage(hit)
                playShotSound()
            }
        }

        // Resume pursuit if it moved away
        let dist = calculateDistance(enemy.m_physicalTilePos.x, enemy.m_physicalTilePos.y)
        if dist > Double(m_attackRange) {
            setState(.PURSUING_UNIT)
        }
    }

    private func aimAtUnit(_ enemy: Unit) {
        m_enemy = enemy
        let di = enemy.m_physicalTilePos.x - m_physicalTilePos.x
        let dj = enemy.m_physicalTilePos.y - m_physicalTilePos.y
        // Convertir di/dj a dirección de sprite (8 dirs)
        let angle = atan2(Double(dj), Double(di)) * 180.0 / Double.pi
        let normalized = angle < 0 ? angle + 360 : angle
        let index = Int((normalized + 22.5) / 45.0) % 8
        let mapping = [2, 3, 4, 5, 6, 7, 0, 1]
        m_direction = mapping[index]
    }

    private func calculateDamage() -> Int {
        return m_attackPoints
    }

    func takeDamage(_ danio: Int) {
        m_health -= danio
        if m_health <= 0 {
            m_health = 0
            morir()
        }
    }

    func morir() {
        Log.shared.debug("Me mori.")
        setState(.DYING)
        m_enemy = nil
        if m_type == Res.UNIDAD_PATRICIO {
            Sound.shared.play(Res.SFX_MUERTE_PATRICIO, 0)
        }
    }

    private func updateDyingState() {
        if m_count == 0 {
            let anim = firstAnimation() + m_direction
            m_sprite?.setAnimation(anim)
            m_sprite?.loop = false
            m_sprite?.play()
        }

        if m_sprite?.isAnimationDone() == true {
            m_sprite?.setFrame(m_sprite!.frameCount - 1)
            m_sprite?.stop()
        }

        m_count += 1
        if m_count >= CUENTA_FRAME_MUERTO {
            setState(.DEAD)
        }
    }

    private func playShotSound() {
        let sfx = m_type == 0 ? Res.SFX_DISPARO_PATRICIO : Res.SFX_DISPARO_INGLES
        Sound.shared.play(sfx, 0)
    }

    // MARK: - Healing

    private func updateHealingState() {
        m_recoveryTicks += 1
        if m_recoveryTicks >= m_ticksPerRecovery {
            m_recoveryTicks = 0
            m_health = min(m_health + m_recoveryPoints, m_resistancePoints)
        }
        if m_health >= m_resistancePoints {
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

        m_type = id

        for line in contenido.components(separatedBy: .newlines) {
            let partes = line.components(separatedBy: ";")
            guard partes.count >= 2 else { continue }
            let clave = partes[0].trimmingCharacters(in: .whitespaces)
            let value = partes[1].trimmingCharacters(in: .whitespaces)

            switch clave {
            case "Sprite":
                let spriteIdx = value == "patricio" ? Res.SPR_PATRICIO : Res.SPR_INGLES
                m_firstSprite = 0  // animaciones comienzan en 0 dentro del sprite
                let sprs = ResourceManager.shared.sprites
                if spriteIdx >= 0, spriteIdx < sprs.count, let spr = sprs[spriteIdx] {
                    m_sprite = Sprite(copia: spr)
                }
            case "Velocidad":
                let v = Int(value) ?? 2
                m_currentSpeed     = (v, v)
                m_defaultSpeed = (v, v)
            case "Puntos_Resistencia":
                let pr = Int(value) ?? 100
                m_resistancePoints = pr
                m_health               = pr
            case "Puntos_Ataque":
                m_attackPoints = Int(value) ?? 10
            case "Visibilidad":
                m_visibility = Int(value) ?? 10
            case "Punteria":
                m_aim = Int(value) ?? 5
            case "Alcance_Tiro":
                m_attackRange = Int(value) ?? 5
            case "Intervalo_Entre_Ataques":
                m_attackInterval = Int(value) ?? 30
            case "Nombre":
                m_name = value
            case "Avatar":
                m_avatar = ResourceManager.shared.getImage(value)
            case "Puntos_De_Recuperacion":
                m_recoveryPoints = Int(value) ?? 20
            case "Ticks_Entre_Recuparacion":
                m_ticksPerRecovery = Int(value) ?? 50
            default:
                break
            }
        }
    }

    // MARK: - Check objective order

    private func checkOrderCompleted() {
        guard let ord = m_objectiveCommand else { return }
        if ord.id == .MOVE || ord.id == .TAKE_OBJECT {
            if completedMoveObjective() {
                m_completedOrder = true
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
