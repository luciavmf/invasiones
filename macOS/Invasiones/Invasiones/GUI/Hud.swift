//
//  Hud.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Hud.cs — in-game HUD info header.
//

import Foundation

class Hud {

    // MARK: - Position constants
    static let AVATAR_X         = 61
    static let AVATAR_Y         = 11
    static let AVATAR_NAME_X  = 126
    static let AVATAR_NAME_WIDTH = 82
    static let AVATAR_NAME_Y  = 6
    static let ATTRS_START_X1 = 141
    static let ATTRS_START_X2 = 215
    static let ATTRS_START_X3 = 338
    static let ATTRS_START_Y   = 25
    static let ATTRS_COUNT_Y     = 35
    static let ATTRS_ENEMY_COUNT_X = 705
    static let ATTRS_ARGENTINE_COUNT_X  = 570

    // MARK: - Declarations
    private var m_image:            Surface?
    private var m_unitToShow:    Unit?
    private var m_enemyCount:  Int = 0
    private var m_argentineCount:Int = 0
    private var m_y:                 Int = 0
    private let m_lineSpacing    = 12
    private var m_tipsWindow:        Tips

    // MARK: - Properties
    var selectedUnit: Unit? {
        set { m_unitToShow = newValue }
        get { m_unitToShow }
    }

    var argentineCount: Int {
        get { m_argentineCount }
        set { m_argentineCount = newValue }
    }

    var enemyCount: Int {
        get { m_enemyCount }
        set { m_enemyCount = newValue }
    }

    var height: Int { m_image?.height ?? 0 }

    // MARK: - Initializer
    init() {
        m_image     = ResourceManager.shared.getImage(Res.IMG_HUD)
        m_y          = Video.height - (m_image?.height ?? 0)
        m_tipsWindow = Tips()
        m_tipsWindow.setPosition(
            ((Video.width - m_tipsWindow.width) / 2) + 175,
            m_y - m_tipsWindow.height - 75,
            0)
    }

    // MARK: - Update
    func update() {
        if let u = m_unitToShow, u.isDead() {
            m_unitToShow = nil
        }
        m_tipsWindow.update()
    }

    // MARK: - Draw
    func draw(_ g: Video) {
        if let img = m_image {
            // V_FONDO = draws at the bottom
            g.draw(img, 0, m_y, 0)
        }
        m_tipsWindow.draw(g)

        g.setFont(ResourceManager.shared.fonts[Definitions.FNT.SANS12.rawValue],
                       Definitions.COLOR_BLACK)
        g.write("\(m_enemyCount)",   Hud.ATTRS_ENEMY_COUNT_X, m_y + Hud.ATTRS_COUNT_Y, 0)
        g.write("\(m_argentineCount)", Hud.ATTRS_ARGENTINE_COUNT_X,  m_y + Hud.ATTRS_COUNT_Y, 0)

        g.setFont(ResourceManager.shared.fonts[Definitions.FNT.SANS12.rawValue],
                       Definitions.COLOR_WHITE)

        guard let uni = m_unitToShow else { return }

        if let av = uni.avatar {
            g.draw(av, Hud.AVATAR_X, m_y + Hud.AVATAR_Y, 0)
        }
        g.write(uni.name, Hud.AVATAR_NAME_X, m_y + Hud.AVATAR_NAME_Y, 0)

        g.setColor(Definitions.COLOR_BLACK)

        let s = GameText.Strings
        g.write("\(s[safe: Res.STR_ALCANCE] ?? ""):\(uni.range)",
                   Hud.ATTRS_START_X1, m_y + Hud.ATTRS_START_Y, 0)
        g.write("\(s[safe: Res.STR_PUNTERIA] ?? ""):\(uni.aim)",
                   Hud.ATTRS_START_X1, m_y + Hud.ATTRS_START_Y + m_lineSpacing, 0)
        g.write("\(s[safe: Res.STR_PUNTOS_DE_ATAQUE] ?? ""):\(uni.attackPoints)",
                   Hud.ATTRS_START_X2, m_y + Hud.ATTRS_START_Y, 0)
        g.write("\(s[safe: Res.STR_PUNTOS_DE_RESISTENCIA] ?? ""):\(uni.health)/\(uni.resistancePoints)",
                   Hud.ATTRS_START_X2, m_y + Hud.ATTRS_START_Y + m_lineSpacing, 0)
        g.write("\(s[safe: Res.STR_VELOCIDAD] ?? ""):\(uni.defaultSpeed)",
                   Hud.ATTRS_START_X3, m_y + Hud.ATTRS_START_Y, 0)
        g.write("\(s[safe: Res.STR_VISIBILIDAD] ?? ""):\(uni.visibility)",
                   Hud.ATTRS_START_X3, m_y + Hud.ATTRS_START_Y + m_lineSpacing, 0)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
