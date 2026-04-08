//
//  EnemyFaction.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of BandoEnemigo.cs — AI-controlled faction.
//

import Foundation

/// The AI-controlled enemy faction.
/// Loads enemy units from the map, assigns scripted AI orders to groups, and sends ungrouped units to patrol.
class EnemyTeam: Player {

    // MARK: - Initializer
    override init(map: Map, camera: Camera, objectsToDraw: ObjectTable, hud: Hud) {
        super.init(map: map, camera: camera, objectsToDraw: objectsToDraw, hud: hud)
        faction = .enemy
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
        guard let unitsTileset = map.tilesets.first(where: {
            $0?.id == Res.TLS_UNIDADES
        }) else { return }
        guard let ts = unitsTileset else { return }

        units = []

        for i in 0..<map.width {
            for j in 0..<map.height {
                let tileId = map.unitsLayer[i][j]
                guard tileId != 0 else { continue }

                let localId = tileId - ts.firstGid
                guard localId >= 0, localId < ts.tiles.count,
                      let tile = ts.tiles[localId],
                      tile.id == Res.TILE_UNIDADES_ID_INGLES else { continue }

                let list = placeUnits(type: Res.UNIDAD_INGLES, count: tile.count, x: i << 1, y: j << 1)

                if list.count > 1 {
                    if groups == nil { groups = [] }
                    let newGroup = Group(list)
                    let ia = IA()
                    ia.load(x: i, y: j, levelIndex: levelIndex)
                    newGroup.setAI(ia)
                    groups!.append(newGroup)
                } else {
                    list.forEach { $0.patrol() }
                }
            }
        }
    }

    // MARK: - Private

    private func updateGameplayState() {
        selectedUnits = []
        updateUnits()
        removeDeadUnits()
        updateOrders()
        updateGroups()
    }

    private func updateGroups() {
        groups?.forEach { $0.update() }
    }

    private func updateOrders() {
        guard !selectedUnits.isEmpty else { return }
        if Mouse.shared.pressedButtons.contains(Mouse.Constants.leftButton) {
            selectedUnits.forEach { $0.isSelected = false }
            clearSelection()
        }
    }
}
