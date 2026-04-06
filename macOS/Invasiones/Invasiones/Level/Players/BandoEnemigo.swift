//
//  EnemyFaction.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of BandoEnemigo.cs — AI-controlled faction.
//

import Foundation

class EnemyTeam: Player {

    // MARK: - Initializer
    override init(map: Map, camera: Camera, objectsToDraw: ObjectTable, hud: Hud) {
        super.init(map: map, camera: camera, objectsToDraw: objectsToDraw, hud: hud)
        m_faction = .ENEMY
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
        guard let tilesetUnidades = m_map.tilesets.first(where: {
            $0?.id == Int16(Res.TLS_UNIDADES)
        }) else { return true }
        guard let ts = tilesetUnidades else { return true }

        m_units = []

        for i in 0..<m_map.width {
            for j in 0..<m_map.height {
                let tileId = Int(m_map.unitsLayer[i][j])
                guard tileId != 0 else { continue }

                let localId = tileId - Int(ts.firstGid)
                guard localId >= 0, localId < ts.tiles.count,
                      let tile = ts.tiles[localId],
                      tile.id == Int16(Res.TILE_UNIDADES_ID_INGLES) else { continue }

                let list = placeUnits(Res.UNIDAD_INGLES, tile.count, i << 1, j << 1)

                if list.count > 1 {
                    if m_groups == nil { m_groups = [] }
                    let newGroup = Group(list)
                    let ia = IA()
                    ia.load(i, j, levelIndex)
                    newGroup.setAI(ia)
                    m_groups!.append(newGroup)
                } else {
                    list.forEach { $0.patrol() }
                }
            }
        }
        return true
    }

    // MARK: - Private

    private func updateGameplayState() {
        m_selectedUnits = []
        updateUnits()
        removeDeadUnits()
        updateOrders()
        updateGroups()
    }

    private func updateGroups() {
        m_groups?.forEach { $0.update() }
    }

    private func updateOrders() {
        guard !m_selectedUnits.isEmpty else { return }
        if Mouse.shared.pressedButtons.contains(Mouse.BUTTON_LEFT) {
            m_selectedUnits.forEach { $0.isSelected = false }
            clearSelection()
        }
    }
}
