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
    static let AVATAR_X = 61
    static let AVATAR_Y = 11
    static let AVATAR_NAME_X = 126
    static let AVATAR_NAME_WIDTH = 82
    static let AVATAR_NAME_Y = 6
    static let ATTRS_START_X1 = 141
    static let ATTRS_START_X2 = 215
    static let ATTRS_START_X3 = 338
    static let ATTRS_START_Y = 25
    static let ATTRS_COUNT_Y = 35
    static let ATTRS_ENEMY_COUNT_X = 705
    static let ATTRS_ARGENTINE_COUNT_X = 570

    // MARK: - Declarations
    private var image: Surface?
    private var unitToShow: Unit?
    var enemyCount: Int = 0
    var argentineCount: Int = 0
    private var posY: Int = 0
    private let lineSpacing = 12
    private var tipsWindow: Tips

    // MARK: - Properties
    var selectedUnit: Unit? {
        set { unitToShow = newValue }
        get { unitToShow }
    }

    var height: Int { image?.height ?? 0 }

    // MARK: - Initializer
    init() {
        image = ResourceManager.shared.getImage(Res.IMG_HUD)
        posY = Video.height - (image?.height ?? 0)
        tipsWindow = Tips()
        tipsWindow.setPosition(
            x: ((Video.width - tipsWindow.width) / 2) + 175,
            y: posY - tipsWindow.height - 75,
            anchor: 0)
    }

    // MARK: - Update
    func update() {
        if let u = unitToShow, u.isDead() {
            unitToShow = nil
        }
        tipsWindow.update()
    }

    // MARK: - Draw
    func draw(_ g: Video) {
        if let img = image {
            // V_FONDO = draws at the bottom
            g.draw(img, 0, posY, 0)
        }
        tipsWindow.draw(g)

        g.setFont(ResourceManager.shared.fonts[FontIndex.sans12.rawValue],
                       GameColor.black)
        g.write("\(enemyCount)", Hud.ATTRS_ENEMY_COUNT_X, posY + Hud.ATTRS_COUNT_Y, 0)
        g.write("\(argentineCount)", Hud.ATTRS_ARGENTINE_COUNT_X, posY + Hud.ATTRS_COUNT_Y, 0)

        g.setFont(ResourceManager.shared.fonts[FontIndex.sans12.rawValue],
                       GameColor.white)

        guard let uni = unitToShow else { return }

        if let av = uni.avatar {
            g.draw(av, Hud.AVATAR_X, posY + Hud.AVATAR_Y, 0)
        }
        g.write(uni.name, Hud.AVATAR_NAME_X, posY + Hud.AVATAR_NAME_Y, 0)

        g.setColor(GameColor.black)

        let s = GameText.Strings
        g.write("\(s[safe: Res.STR_ALCANCE] ?? ""):\(uni.range)",
                   Hud.ATTRS_START_X1, posY + Hud.ATTRS_START_Y, 0)
        g.write("\(s[safe: Res.STR_PUNTERIA] ?? ""):\(uni.aim)",
                   Hud.ATTRS_START_X1, posY + Hud.ATTRS_START_Y + lineSpacing, 0)
        g.write("\(s[safe: Res.STR_PUNTOS_DE_ATAQUE] ?? ""):\(uni.attackPoints)",
                   Hud.ATTRS_START_X2, posY + Hud.ATTRS_START_Y, 0)
        g.write("\(s[safe: Res.STR_PUNTOS_DE_RESISTENCIA] ?? ""):\(uni.health)/\(uni.resistancePoints)",
                   Hud.ATTRS_START_X2, posY + Hud.ATTRS_START_Y + lineSpacing, 0)
        g.write("\(s[safe: Res.STR_VELOCIDAD] ?? ""):\(uni.defaultSpeed)",
                   Hud.ATTRS_START_X3, posY + Hud.ATTRS_START_Y, 0)
        g.write("\(s[safe: Res.STR_VISIBILIDAD] ?? ""):\(uni.visibility)",
                   Hud.ATTRS_START_X3, posY + Hud.ATTRS_START_Y + lineSpacing, 0)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
