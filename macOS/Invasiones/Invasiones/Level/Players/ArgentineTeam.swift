//
//  ArgentineTeam.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of BandoArgentino.cs — player-controlled faction.
//

import Foundation
internal import CoreGraphics

class ArgentineTeam: Player {

    // MARK: - Attributes
    private var m_unitUnderMouse:            Unit?
    private var m_count:                     Int = 0
    private var m_arrowObj:               MapObject?
    private var m_orientationArrow:          Animation?
    private var m_commandTargetPos:           (x: Int, y: Int) = (0, 0)
    private var m_arrowPos:  (x: Int, y: Int) = (0, 0)
    private var m_unitToFindIdx:     Int = 0

    private let ARROW_MAX_COUNT = 100

    // MARK: - Initializer
    override init(map: Map, camera: Camera, objectsToDraw: ObjectTable, hud: Hud) {
        super.init(map: map, camera: camera, objectsToDraw: objectsToDraw, hud: hud)
        m_faction = .ARGENTINE
        Group.map = map

        let anims = ResourceManager.shared.animations
        if Res.ANIM_AROS < anims.count, let animAros = anims[Res.ANIM_AROS] {
            m_ring = AnimObject(Animation(copia: animAros), 0, 0)
        }

        if Res.ANIM_FLECHA_GUIA < anims.count, let animFlecha = anims[Res.ANIM_FLECHA_GUIA] {
            m_orientationArrow = Animation(copia: animFlecha)
            m_orientationArrow?.load()
        }
    }

    // MARK: - Override

    override func update() {
        switch m_state {
        case .START:   m_state = .LOADING
        case .LOADING: m_state = .GAME
        case .GAME:    updateGameplayState()
        }
    }

    override func loadUnits(_ levelIndex: Int) -> Bool {
        m_arrowObj = MapObject(sup: ResourceManager.shared.getImage(Res.IMG_FLECHA),
                               i: 0, j: 0)
        m_count = 99999

        guard let tilesetUnidades = m_map.tilesets.compactMap({ $0 }).first(where: {
            $0.id == Int16(Res.TLS_UNIDADES)
        }) else { return true }

        m_units = []

        for i in 0..<m_map.width {
            for j in 0..<m_map.height {
                let tileId = Int(m_map.unitsLayer[i][j])
                guard tileId != 0 else { continue }

                let localId = tileId - Int(tilesetUnidades.firstGid)
                guard localId >= 0, localId < tilesetUnidades.tiles.count,
                      let tile = tilesetUnidades.tiles[localId],
                      tile.id == Int16(Res.TILE_UNIDADES_ID_PATRICIO) else { continue }

                let list = placeUnits(Res.UNIDAD_PATRICIO, tile.count, i << 1, j << 1)

                if list.count > 1 {
                    if m_groups == nil { m_groups = [] }
                    m_groups!.append(Group(list))
                }
            }
        }
        return true
    }

    // MARK: - Draw (llamado desde Episode)

    func drawOrientationArrow(_ g: Video) {
        guard m_state == .GAME else { return }

        // Draw objective ring, object to grab, and fire effects
        m_ring?.draw(g)
        m_objectToTake?.draw(g)
        m_fireEffects?.forEach { $0.draw(g) }

        // Draw static destination arrow if there's a recent order
        if m_count < ARROW_MAX_COUNT {
            m_arrowObj?.draw(g)
        }

        // Draw orientation arrow only if objective is off-screen
        guard m_command != nil, m_orientationArrow != nil else { return }
        guard !isObjectiveVisible() else { return }
        m_orientationArrow?.draw(g, m_arrowPos.x,
                                     m_arrowPos.y, 0)
    }

    // MARK: - Rendering coordinates for Episode

    func getPaintCoordinates() -> (x: Int, y: Int, w: Int, h: Int) {
        guard let cam = MapObject.camera else {
            return (0, 0, m_map.physicalMapHeight, m_map.physicalMapWidth)
        }
        let p = calculateFirstTileToDraw(cam.X, cam.Y)
        let tw = m_map.physicalTileWidth > 0 ? m_map.physicalTileWidth : 1
        let th = m_map.physicalTileHeight  > 0 ? m_map.physicalTileHeight  : 1
        let w = (cam.width - cam.startX) / tw + 23
        let h = ((cam.height - cam.startY) / th) * 2 + 78
        return (p.x - 15, p.y - 5, w, h)
    }

    func selectNextUnit() {
        guard !m_units.isEmpty else { return }

        // Center camera on the unit
        let u = m_units[m_unitToFindIdx]
        m_camera.X = (((u.physicalTilePos.y - u.physicalTilePos.x) *
                        m_map.physicalTileWidth) >> 1) + Video.width / 2
        m_camera.Y = ((-(u.physicalTilePos.y + u.physicalTilePos.x) *
                        m_map.physicalTileHeight) >> 1) + Video.height / 2

        m_selectedUnit?.isSelected = false
        m_selectedGroup?.isSelected  = false

        m_selectedUnit = u
        m_selectedUnit?.isSelected = true
        m_hud.selectedUnit = m_selectedUnit

        m_unitToFindIdx += 1
        if m_unitToFindIdx >= m_units.count { m_unitToFindIdx = 0 }
    }

    // MARK: - Private

    private func updateGameplayState() {
        updateOrientationArrow()

        m_objectToTake?.update()
        m_ring?.update()

        m_unitUnderMouse = getUnitUnderMouse()
        m_selectedUnits = []

        selectUnitsInDragRect()
        updateUnits()
        createGroups()
        checkUnitOrders()
        updateCursor()

        m_fireEffects?.forEach { $0.update() }
        updateGroups()
        updateObjectives()
        removeDeadUnits()

        m_arrowObj?.update()
        m_count += 1
    }

    // MARK: - Orientation arrow

    private func updateOrientationArrow() {
        guard let ord = m_command, let flecha = m_orientationArrow else { return }

        // Screen position of the target tile
        m_commandTargetPos.x = (((ord.point.x - ord.point.y) * m_map.tileWidth / 2) >> 1)
                              + m_camera.startX + m_camera.X
        m_commandTargetPos.y = (((ord.point.x + ord.point.y) * m_map.tileHeight  / 2) >> 1)
                              + m_camera.startY + m_camera.Y

        guard !isObjectiveVisible() else { return }

        let cx = Video.width / 2
        let cy = Video.height  / 2
        let a  = Double(m_commandTargetPos.y - cy)
        let b  = Double(m_commandTargetPos.x - cx)

        var degrees = atan(a / b) * 180 / .pi
        if a < 0 && b > 0  { degrees = -degrees }
        if a >= 0 && b < 0 { degrees = 180 - degrees }
        if a < 0  && b < 0 { degrees = 180 - degrees }
        if a > 0  && b >= 0 { degrees = 360 - degrees }

        let factor = 360.0 / 8
        let half  = 360.0 / 16

        let dir: Definitions.DIRECTION
        if      (degrees >= 0 && degrees < half) || degrees > 360 - half { dir = .E  }
        else if degrees >= half          && degrees < half + factor      { dir = .NE }
        else if degrees >= half + factor && degrees < half + factor * 2  { dir = .N  }
        else if degrees >= half + factor * 2 && degrees < half + factor * 3 { dir = .NO }
        else if degrees >= half + factor * 3 && degrees < half + factor * 4 { dir = .O  }
        else if degrees >= half + factor * 4 && degrees < half + factor * 5 { dir = .SO }
        else if degrees >= half + factor * 5 && degrees < half + factor * 6 { dir = .S  }
        else                                                                 { dir = .SE }

        let OFFSET = -20
        let fw = flecha.frameWidth
        let fh = flecha.frameHeight

        if m_commandTargetPos.x > m_camera.startX &&
           m_commandTargetPos.x < m_camera.width - fw + OFFSET {
            m_arrowPos.x = m_commandTargetPos.x
        } else if m_commandTargetPos.x <= m_camera.startX {
            m_arrowPos.x = -OFFSET
        } else {
            m_arrowPos.x = m_camera.width - fw + OFFSET
        }

        if m_commandTargetPos.y > m_camera.startY &&
           m_commandTargetPos.y < m_camera.height - fh + OFFSET {
            m_arrowPos.y = m_commandTargetPos.y
        } else if m_commandTargetPos.y <= m_camera.startY {
            m_arrowPos.y = -OFFSET
        } else {
            m_arrowPos.y = m_camera.height - fh + OFFSET
        }

        flecha.setAnimation(dir.rawValue)
    }

    private func isObjectiveVisible() -> Bool {
        return m_commandTargetPos.x > m_camera.startX &&
               m_commandTargetPos.x < m_camera.width   &&
               m_commandTargetPos.y > m_camera.startY  &&
               m_commandTargetPos.y < m_camera.height
    }

    // MARK: - Unit under mouse

    private func getUnitUnderMouse() -> Unit? {
        let rect = getPaintCoordinates()
        var XX = rect.x, YY = rect.y
        let endI = rect.w, endJ = rect.h
        var tileY = 0, toggle = true

        while tileY <= endJ {
            var tileX = 0
            var i = XX, j = YY
            while tileX <= endI && j >= 0 {
                if i >= 0 && i < m_map.physicalMapHeight && j < m_map.physicalMapWidth {
                    if let uni = m_objectsToDraw.tabla[i][j] as? Unit,
                       uni.isUnderMouse() {
                        return uni
                    }
                }
                tileX += 1; i += 1; j -= 1
            }
            tileY += 1
            if toggle { XX += 1; toggle = false }
            else       { YY += 1; toggle = true  }
        }
        return nil
    }

    // MARK: - Orders

    private func checkUnitOrders() {
        // Left click on an Argentine unit: select it
        if Mouse.shared.pressedButtons.contains(Mouse.BUTTON_LEFT) {
            if let unitUnderMouse = m_unitUnderMouse, unitUnderMouse.faction == .ARGENTINE {
                let up = Mouse.shared.dragRect
                let isDragging = Mouse.shared.isDragging()
                    && Int(up.width) >= 4 && Int(up.height) >= 4
                if !isDragging {
                    clearSelection()
                    unitUnderMouse.isSelected = true
                    m_hud.selectedUnit  = unitUnderMouse
                    m_selectedUnit      = unitUnderMouse

                    if unitUnderMouse.belongsToGroup {
                        unitUnderMouse.myGroup?.removeUnit(unitUnderMouse)
                        unitUnderMouse.leaveGroup()
                    }
                    Mouse.shared.releaseButton(Mouse.BUTTON_LEFT)
                }
            }
        }

        guard m_selectedUnit != nil || m_selectedGroup != nil else { return }

        // Right click: move or attack
        if Mouse.shared.pressedButtons.contains(Mouse.BUTTON_RIGHT) {
            Mouse.shared.releaseButton(Mouse.BUTTON_RIGHT)

            let tile = m_map.smallTileUnderMouse

            if m_map.isWalkable(tile.x, tile.y) {
                // There is an enemy unit under the mouse → attack
                if let unitUnderMouse = m_unitUnderMouse,
                   unitUnderMouse.faction == .ENEMY,
                   !unitUnderMouse.isDead() {
                    if let group = m_selectedGroup {
                        group.attack(unitUnderMouse)
                    } else {
                        m_selectedUnit?.attack(unitUnderMouse)
                    }
                } else {
                    // Mover
                    if let group = m_selectedGroup {
                        group.move(tile.x, tile.y)
                    } else {
                        m_selectedUnit?.move(tile.x, tile.y)
                    }
                    m_count = 0
                    m_arrowObj?.setTilePosition(tile.x, tile.y)
                }
            } else {
                // Non-walkable tile: check if it's the infirmary
                let tileUnderMouse = m_map.tileUnderMouse
                guard tileUnderMouse.y < m_map.height  && tileUnderMouse.y >= 0 &&
                      tileUnderMouse.x < m_map.width && tileUnderMouse.x >= 0 else { return }

                let buildingTileId = Int(m_map.buildingsLayer[tileUnderMouse.x][tileUnderMouse.y])
                guard buildingTileId != 0, let ts = m_map.getTileset(buildingTileId) else { return }

                let localId = buildingTileId - Int(ts.firstGid)
                guard localId >= 0, localId < ts.tiles.count,
                      let tileProp = ts.tiles[localId],
                      ts.id == Int16(Res.TLS_INVALIDADO),
                      tileProp.id == Int16(Res.TILE_INVALIDADOS_ID_ENFERMERIA) else { return }

                Log.shared.debug("Me llevan a heal.")
                if let group = m_selectedGroup,
                   group.health < group.resistancePoints {
                    group.heal(tile.x, tile.y)
                } else if let unit = m_selectedUnit,
                          unit.health < unit.resistancePoints {
                    unit.heal(tile.x, tile.y)
                }
            }
        }

        // Left click without dragging: deselect
        if Mouse.shared.pressedButtons.contains(Mouse.BUTTON_LEFT) {
            let up = Mouse.shared.dragRect
            let isDragging = Mouse.shared.isDragging()
                && Int(up.width) >= 4 && Int(up.height) >= 4
            if !isDragging {
                m_selectedUnits.forEach { $0.isSelected = false }
                clearSelection()
            }
        }
    }

    // MARK: - Group creation and management

    private func createGroups() {
        guard !m_selectedUnits.isEmpty else { return }
        guard m_selectedGroup == nil && m_selectedUnit == nil else { return }

        if m_selectedUnits.count > 1 {
            if m_groups == nil { m_groups = [] }

            for unit in m_selectedUnits {
                if unit.belongsToGroup {
                    unit.myGroup?.removeUnit(unit)
                    unit.leaveGroup()
                }
            }

            m_selectedGroup = Group(m_selectedUnits)
            m_selectedGroup?.isSelected = true
            m_groups!.append(m_selectedGroup!)
        } else {
            m_selectedUnit = m_selectedUnits[0]
        }
    }

    private func updateGroups() {
        guard let grupos = m_groups, !grupos.isEmpty else { return }

        var toRemove: [Group] = []

        for group in grupos {
            group.update()
            if group.currentState == .WAITING_FOR_ORDER && !group.isSelected {
                toRemove.append(group)
            }
            if group.currentState == .ELIMINATED {
                if group === m_selectedGroup {
                    m_selectedGroup = nil
                    if group.soldierCount == 1 {
                        m_selectedUnit = group.getLastUnit()
                    }
                }
                toRemove.append(group)
            }
        }

        for group in toRemove {
            group.dissolve()
            m_groups?.removeAll { $0 === group }
        }
    }

    // MARK: - Cursor

    private func updateCursor() {
        Mouse.shared.setCursor(
            ResourceManager.shared.getImage(Res.IMG_CURSOR))

        guard m_selectedUnit != nil || m_selectedGroup != nil else { return }

        if let unitUnderMouse = m_unitUnderMouse, unitUnderMouse.faction == .ENEMY {
            Mouse.shared.setCursor(
                ResourceManager.shared.getImage(Res.IMG_CURSOR_ESPADA))
        }

        if let u = m_selectedUnit, u.isDead() {
            clearSelection()
        }

        let tileUnderMouse = m_map.tileUnderMouse
        guard tileUnderMouse.y < m_map.height  && tileUnderMouse.y >= 0 &&
              tileUnderMouse.x < m_map.width && tileUnderMouse.x >= 0 else { return }

        let buildingTileId = Int(m_map.buildingsLayer[tileUnderMouse.x][tileUnderMouse.y])
        guard buildingTileId != 0, let ts = m_map.getTileset(buildingTileId) else { return }

        let localId = buildingTileId - Int(ts.firstGid)
        guard localId >= 0, localId < ts.tiles.count,
              let tileProp = ts.tiles[localId],
              ts.id == Int16(Res.TLS_INVALIDADO),
              tileProp.id == Int16(Res.TILE_INVALIDADOS_ID_ENFERMERIA) else { return }

        let needsHeal = (m_selectedUnit.map { $0.health < $0.resistancePoints } ?? false)
                     || (m_selectedGroup.map  { $0.health < $0.resistancePoints } ?? false)
        if needsHeal {
            Mouse.shared.setCursor(
                ResourceManager.shared.getImage(Res.IMG_CURSOR_ENFERMERIA))
        }
    }

    // MARK: - Objetivos

    private func updateObjectives() {
        guard m_someoneCompletedOrder else { return }

        if m_command?.id == .TAKE_OBJECT {
            m_objectToTake = nil
        }

        setNextCommand()

        if m_command == nil {
            m_completedObjective = true
            Log.shared.debug("Se cumplio con el objetivo deseado!!!!!!!")
        }
    }

    // MARK: - Private helpers

    private func selectUnitsInDragRect() {
        // Fire on the frame the drag ends (matches original C# TerminoDeArrastrar() check).
        guard Mouse.shared.didFinishDragging() else { return }

        let up = Mouse.shared.dragRect
        guard Int(up.width) >= 4 && Int(up.height) >= 4 else { return }

        guard m_selectedUnit == nil && m_selectedGroup == nil else { return }

        for unit in m_units where unit.faction == .ARGENTINE {
            _ = unit.selectIfInRect(
                Int(up.origin.x), Int(up.origin.y),
                Int(up.width),    Int(up.height))
        }
    }

    private func calculateFirstTileToDraw(_ x: Int, _ y: Int) -> (x: Int, y: Int) {
        let th = m_map.tileHeight > 0 ? m_map.tileHeight / 2 : 1
        let tw = m_map.tileWidth > 0 ? m_map.tileWidth / 2 : 1
        let a = -y / th
        var b =  x / tw
        if x > 0 { b += 1 }
        return (a - b - 4, a + b - 2)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
