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

/// The player-controlled Argentine faction.
/// Handles mouse-driven unit selection, movement orders, attack orders, group creation,
/// the orientation arrow, and objective progress.
class ArgentineTeam: Player {

    // MARK: - Attributes
    private var unitUnderMouse: Unit?
    private var count: Int = 0
    private var arrowObj: MapObject?
    private var orientationArrow: Animation?
    private var commandTargetPos: (x: Int, y: Int) = (0, 0)
    private var arrowPos: (x: Int, y: Int) = (0, 0)
    private var unitToFindIdx: Int = 0

    private let arrowMaxCount = 100

    // MARK: - Initializer
    override init(map: Map, camera: Camera, objectsToDraw: ObjectTable, hud: Hud) {
        super.init(map: map, camera: camera, objectsToDraw: objectsToDraw, hud: hud)
        faction = .argentine
        Group.map = map

        let anims = ResourceManager.shared.animations
        if Res.ANIM_AROS < anims.count, let animAros = anims[Res.ANIM_AROS] {
            ring = AnimObject(Animation(copia: animAros), 0, 0)
        }

        if Res.ANIM_FLECHA_GUIA < anims.count, let animFlecha = anims[Res.ANIM_FLECHA_GUIA] {
            orientationArrow = Animation(copia: animFlecha)
            try? orientationArrow?.load()
        }
    }

    // MARK: - Override

    override func update() {
        switch stateValue {
        case .start: stateValue = .loading
        case .loading: stateValue = .game
        case .game: updateGameplayState()
        }
    }

    override func loadUnits(_ levelIndex: Int) throws {
        arrowObj = MapObject(sup: ResourceManager.shared.getImage(Res.IMG_FLECHA),
                               i: 0, j: 0)
        count = 99999

        guard let unitsTileset = map.tilesets.compactMap({ $0 }).first(where: {
            $0.id == Res.TLS_UNIDADES
        }) else { return }

        units = []

        for i in 0..<map.width {
            for j in 0..<map.height {
                let tileId = map.unitsLayer[i][j]
                guard tileId != 0 else { continue }

                let localId = tileId - unitsTileset.firstGid
                guard localId >= 0, localId < unitsTileset.tiles.count,
                      let tile = unitsTileset.tiles[localId],
                      tile.id == Res.TILE_UNIDADES_ID_PATRICIO else { continue }

                let list = placeUnits(type: Res.UNIDAD_PATRICIO, count: tile.count, x: i << 1, y: j << 1)

                if list.count > 1 {
                    if groups == nil { groups = [] }
                    groups!.append(Group(list))
                }
            }
        }
    }

    // MARK: - Draw (llamado desde Episode)

    /// Draws the objective ring, the collectible object, fire effects, the destination arrow, and the orientation arrow.
    func drawOrientationArrow(_ video: Video) {
        guard stateValue == .game else { return }

        // Draw objective ring, object to grab, and fire effects
        ring?.draw(video)
        objectToTake?.draw(video)
        fireEffects?.forEach { $0.draw(video) }

        // Draw static destination arrow if there's a recent order
        if count < arrowMaxCount {
            arrowObj?.draw(video)
        }

        // Draw orientation arrow only if objective is off-screen
        guard command != nil, orientationArrow != nil else { return }
        guard !isObjectiveVisible() else { return }
        orientationArrow?.draw(video: video, x: arrowPos.x, y: arrowPos.y, anchor: 0)
    }

    // MARK: - Rendering coordinates for Episode

    /// Calculates the range of tile coordinates that are visible in the current camera view.
    /// Used by Episode to determine which objects to draw each frame.
    /// - Returns: (x, y) of the first tile to draw, (w, h) as the tile count in each dimension.
    func getPaintCoordinates() -> (x: Int, y: Int, w: Int, h: Int) {
        guard let cam = MapObject.camera else {
            return (0, 0, map.physicalMapHeight, map.physicalMapWidth)
        }
        let p = calculateFirstTileToDraw(x: cam.x, y: cam.y)
        let tw = map.physicalTileWidth > 0 ? map.physicalTileWidth : 1
        let th = map.physicalTileHeight > 0 ? map.physicalTileHeight : 1
        let w = (cam.width - cam.startX) / tw + 23
        let h = ((cam.height - cam.startY) / th) * 2 + 78
        return (p.x - 15, p.y - 5, w, h)
    }

    /// Selects the next Argentine unit in sequence and centers the camera on it.
    func selectNextUnit() {
        guard !units.isEmpty else { return }

        // Center camera on the unit
        let u = units[unitToFindIdx]
        camera.x = (((u.physicalTilePos.y - u.physicalTilePos.x) *
                        map.physicalTileWidth) >> 1) + Video.width / 2
        camera.y = ((-(u.physicalTilePos.y + u.physicalTilePos.x) *
                        map.physicalTileHeight) >> 1) + Video.height / 2

        selectedUnit?.isSelected = false
        selectedGroup?.isSelected  = false

        selectedUnit = u
        selectedUnit?.isSelected = true
        hud.selectedUnit = selectedUnit

        unitToFindIdx += 1
        if unitToFindIdx >= units.count { unitToFindIdx = 0 }
    }

    // MARK: - Private

    private func updateGameplayState() {
        updateOrientationArrow()

        objectToTake?.update()
        ring?.update()

        unitUnderMouse = getUnitUnderMouse()
        selectedUnits = []

        selectUnitsInDragRect()
        updateUnits()
        createGroups()
        checkUnitOrders()
        updateCursor()

        fireEffects?.forEach { $0.update() }
        updateGroups()
        updateObjectives()
        removeDeadUnits()

        arrowObj?.update()
        count += 1
    }

    // MARK: - Orientation arrow

    private func updateOrientationArrow() {
        guard let ord = command, let flecha = orientationArrow else { return }

        // Screen position of the target tile
        commandTargetPos.x = (((ord.point.x - ord.point.y) * map.tileWidth / 2) >> 1)
                              + camera.startX + camera.x
        commandTargetPos.y = (((ord.point.x + ord.point.y) * map.tileHeight  / 2) >> 1)
                              + camera.startY + camera.y

        guard !isObjectiveVisible() else { return }

        let cx = Video.width / 2
        let cy = Video.height  / 2
        let a = Double(commandTargetPos.y - cy)
        let b = Double(commandTargetPos.x - cx)

        var degrees = atan(a / b) * 180 / .pi
        if a < 0 && b > 0  { degrees = -degrees }
        if a >= 0 && b < 0 { degrees = 180 - degrees }
        if a < 0  && b < 0 { degrees = 180 - degrees }
        if a > 0  && b >= 0 { degrees = 360 - degrees }

        let factor = 360.0 / 8
        let half = 360.0 / 16

        let dir: Direction
        if      (degrees >= 0 && degrees < half) || degrees > 360 - half { dir = .east      }
        else if degrees >= half          && degrees < half + factor      { dir = .northEast  }
        else if degrees >= half + factor && degrees < half + factor * 2  { dir = .north      }
        else if degrees >= half + factor * 2 && degrees < half + factor * 3 { dir = .northWest }
        else if degrees >= half + factor * 3 && degrees < half + factor * 4 { dir = .west      }
        else if degrees >= half + factor * 4 && degrees < half + factor * 5 { dir = .southWest }
        else if degrees >= half + factor * 5 && degrees < half + factor * 6 { dir = .south     }
        else                                                                 { dir = .southEast }

        let offset = -20
        let fw = flecha.frameWidth
        let fh = flecha.frameHeight

        if commandTargetPos.x > camera.startX &&
           commandTargetPos.x < camera.width - fw + offset {
            arrowPos.x = commandTargetPos.x
        } else if commandTargetPos.x <= camera.startX {
            arrowPos.x = -offset
        } else {
            arrowPos.x = camera.width - fw + offset
        }

        if commandTargetPos.y > camera.startY &&
           commandTargetPos.y < camera.height - fh + offset {
            arrowPos.y = commandTargetPos.y
        } else if commandTargetPos.y <= camera.startY {
            arrowPos.y = -offset
        } else {
            arrowPos.y = camera.height - fh + offset
        }

        flecha.setAnimation(anim: dir.rawValue)
    }

    private func isObjectiveVisible() -> Bool {
        return commandTargetPos.x > camera.startX &&
               commandTargetPos.x < camera.width   &&
               commandTargetPos.y > camera.startY  &&
               commandTargetPos.y < camera.height
    }

    // MARK: - Unit under mouse

    private func getUnitUnderMouse() -> Unit? {
        let rect = getPaintCoordinates()
        var startCol = rect.x, startRow = rect.y
        let endI = rect.w, endJ = rect.h
        var tileY = 0, toggle = true

        while tileY <= endJ {
            var tileX = 0
            var i = startCol, j = startRow
            while tileX <= endI && j >= 0 {
                if i >= 0 && i < map.physicalMapHeight && j < map.physicalMapWidth {
                    if let uni = objectsToDraw.tabla[i][j] as? Unit,
                       uni.isUnderMouse() {
                        return uni
                    }
                }
                tileX += 1
                i += 1
                j -= 1
            }
            tileY += 1
                        if toggle {
                startCol += 1
                toggle = false
            }
                        else {
                startRow += 1
                toggle = true
            }
        }
        return nil
    }

    // MARK: - Orders

    private func checkUnitOrders() {
        // Left click on an Argentine unit: select it
        if Mouse.shared.pressedButtons.contains(Mouse.Constants.leftButton) {
            if let unitUnderMouse = unitUnderMouse, unitUnderMouse.faction == .argentine {
                let up = Mouse.shared.dragRect
                let isDragging = Mouse.shared.isDragging()
                    && Int(up.width) >= 4 && Int(up.height) >= 4
                if !isDragging {
                    clearSelection()
                    unitUnderMouse.isSelected = true
                    hud.selectedUnit = unitUnderMouse
                    selectedUnit = unitUnderMouse

                    if unitUnderMouse.belongsToGroup {
                        unitUnderMouse.myGroup?.removeUnit(unitUnderMouse)
                        unitUnderMouse.leaveGroup()
                    }
                    Mouse.shared.releaseButton(Mouse.Constants.leftButton)
                }
            }
        }

        guard selectedUnit != nil || selectedGroup != nil else { return }

        // Right click: move or attack
        if Mouse.shared.pressedButtons.contains(Mouse.Constants.rightButton) {
            Mouse.shared.releaseButton(Mouse.Constants.rightButton)

            let tile = map.smallTileUnderMouse

            if map.isWalkable(x: tile.x, y: tile.y) {
                // There is an enemy unit under the mouse → attack
                if let unitUnderMouse = unitUnderMouse,
                   unitUnderMouse.faction == .enemy,
                   !unitUnderMouse.isDead() {
                    if let group = selectedGroup {
                        group.attack(enemy: unitUnderMouse)
                    } else {
                        selectedUnit?.attack(enemy: unitUnderMouse)
                    }
                } else {
                    // Mover
                    if let group = selectedGroup {
                        group.move(x: tile.x, y: tile.y)
                    } else {
                        selectedUnit?.move(x: tile.x, y: tile.y)
                    }
                    count = 0
                    arrowObj?.setTilePosition(i: tile.x, j: tile.y)
                }
            } else {
                // Non-walkable tile: check if it's the infirmary
                let tileUnderMouse = map.tileUnderMouse
                guard tileUnderMouse.y < map.height  && tileUnderMouse.y >= 0 &&
                      tileUnderMouse.x < map.width && tileUnderMouse.x >= 0 else { return }

                let buildingTileId = map.buildingsLayer[tileUnderMouse.x][tileUnderMouse.y]
                guard buildingTileId != 0, let ts = map.getTileset(buildingTileId) else { return }

                let localId = buildingTileId - ts.firstGid
                guard localId >= 0, localId < ts.tiles.count,
                      let tileProp = ts.tiles[localId],
                      ts.id == Res.TLS_INVALIDADO,
                      tileProp.id == Res.TILE_INVALIDADOS_ID_ENFERMERIA else { return }

                Log.shared.debug("Unit ordered to heal.")
                if let group = selectedGroup,
                   group.health < group.resistancePoints {
                    group.heal(x: tile.x, y: tile.y)
                } else if let unit = selectedUnit,
                          unit.health < unit.resistancePoints {
                    unit.heal(x: tile.x, y: tile.y)
                }
            }
        }

        // Left click without dragging: deselect
        if Mouse.shared.pressedButtons.contains(Mouse.Constants.leftButton) {
            let up = Mouse.shared.dragRect
            let isDragging = Mouse.shared.isDragging()
                && Int(up.width) >= 4 && Int(up.height) >= 4
            if !isDragging {
                selectedUnits.forEach { $0.isSelected = false }
                clearSelection()
            }
        }
    }

    // MARK: - Group creation and management

    private func createGroups() {
        guard !selectedUnits.isEmpty else { return }
        guard selectedGroup == nil && selectedUnit == nil else { return }

        if selectedUnits.count > 1 {
            if groups == nil { groups = [] }

            for unit in selectedUnits {
                if unit.belongsToGroup {
                    unit.myGroup?.removeUnit(unit)
                    unit.leaveGroup()
                }
            }

            let group = Group(selectedUnits)
            group.isSelected = true
            selectedGroup = group
            groups?.append(group)
        } else {
            selectedUnit = selectedUnits[0]
        }
    }

    private func updateGroups() {
        guard let grupos = groups, !grupos.isEmpty else { return }

        var toRemove: [Group] = []

        for group in grupos {
            group.update()
            if group.currentState == .waitingCommand && !group.isSelected {
                toRemove.append(group)
            }
            if group.currentState == .eliminating {
                if group === selectedGroup {
                    selectedGroup = nil
                    if group.soldierCount == 1 {
                        selectedUnit = group.getLastUnit()
                    }
                }
                toRemove.append(group)
            }
        }

        for group in toRemove {
            group.dissolve()
            groups?.removeAll { $0 === group }
        }
    }

    // MARK: - Cursor

    private func updateCursor() {
        Mouse.shared.setCursor(
            ResourceManager.shared.getImage(Res.IMG_CURSOR))

        guard selectedUnit != nil || selectedGroup != nil else { return }

        if let unitUnderMouse = unitUnderMouse, unitUnderMouse.faction == .enemy {
            Mouse.shared.setCursor(
                ResourceManager.shared.getImage(Res.IMG_CURSOR_ESPADA))
        }

        if let u = selectedUnit, u.isDead() {
            clearSelection()
        }

        let tileUnderMouse = map.tileUnderMouse
        guard tileUnderMouse.y < map.height  && tileUnderMouse.y >= 0 &&
              tileUnderMouse.x < map.width && tileUnderMouse.x >= 0 else { return }

        let buildingTileId = map.buildingsLayer[tileUnderMouse.x][tileUnderMouse.y]
        guard buildingTileId != 0, let ts = map.getTileset(buildingTileId) else { return }

        let localId = buildingTileId - ts.firstGid
        guard localId >= 0, localId < ts.tiles.count,
              let tileProp = ts.tiles[localId],
              ts.id == Res.TLS_INVALIDADO,
              tileProp.id == Res.TILE_INVALIDADOS_ID_ENFERMERIA else { return }

        let needsHeal = (selectedUnit.map { $0.health < $0.resistancePoints } ?? false)
                     || (selectedGroup.map  { $0.health < $0.resistancePoints } ?? false)
        if needsHeal {
            Mouse.shared.setCursor(
                ResourceManager.shared.getImage(Res.IMG_CURSOR_ENFERMERIA))
        }
    }

    // MARK: - Objetivos

    private func updateObjectives() {
        guard someoneCompletedOrder else { return }

        if command?.id == .takeObject {
            objectToTake = nil
        }

        setNextCommand()

        if command == nil {
            objectiveCompleted = true
            Log.shared.debug("Objective completed.")
        }
    }

    // MARK: - Private helpers

    private func selectUnitsInDragRect() {
        // Fire on the frame the drag ends (matches original C# TerminoDeArrastrar() check).
        guard Mouse.shared.didFinishDragging() else { return }

        let up = Mouse.shared.dragRect
        guard Int(up.width) >= 4 && Int(up.height) >= 4 else { return }

        guard selectedUnit == nil && selectedGroup == nil else { return }

        for unit in units where unit.faction == .argentine {
            _ = unit.selectIfInRect(
                x: Int(up.origin.x), y: Int(up.origin.y),
                w: Int(up.width),    h: Int(up.height))
        }
    }

    private func calculateFirstTileToDraw(x: Int, y: Int) -> (x: Int, y: Int) {
        let th = map.tileHeight > 0 ? map.tileHeight / 2 : 1
        let tw = map.tileWidth > 0 ? map.tileWidth / 2 : 1
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
