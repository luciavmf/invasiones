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
    private enum Constants {
        static let avatarX = 61
        static let avatarY = 11
        static let avatarNameX = 126
        static let avatarNameWidth = 82
        static let avatarnNameY = 6
        static let attrsStartX1 = 141
        static let attrsStartX2 = 215
        static let attrsStartX3 = 338
        static let attrsStartY = 25
        static let attrsCountY = 35
        static let attrsEnemyCountX = 705
        static let attrsArgentineCountX = 570
    }

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
            anchor: 0
        )
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
        g.write("\(enemyCount)", Constants.attrsEnemyCountX, posY + Constants.attrsCountY, 0)
        g.write("\(argentineCount)", Constants.attrsArgentineCountX, posY + Constants.attrsCountY, 0)

        g.setFont(ResourceManager.shared.fonts[FontIndex.sans12.rawValue],
                       GameColor.white)

        guard let uni = unitToShow else { return }

        if let av = uni.avatar {
            g.draw(av, Constants.avatarX, posY + Constants.avatarY, 0)
        }
        g.write(uni.name, Constants.avatarNameX, posY + Constants.avatarnNameY, 0)

        g.setColor(GameColor.black)

        let s = GameText.Strings
        g.write("\(s[safe: Res.STR_ALCANCE] ?? ""):\(uni.range)",
                Constants.attrsStartX1, posY + Constants.attrsStartY, 0)
        g.write("\(s[safe: Res.STR_PUNTERIA] ?? ""):\(uni.aim)",
                Constants.attrsStartX1, posY + Constants.attrsStartY + lineSpacing, 0)
        g.write("\(s[safe: Res.STR_PUNTOS_DE_ATAQUE] ?? ""):\(uni.attackPoints)",
                Constants.attrsStartX2, posY + Constants.attrsStartY, 0)
        g.write("\(s[safe: Res.STR_PUNTOS_DE_RESISTENCIA] ?? ""):\(uni.health)/\(uni.resistancePoints)",
                Constants.attrsStartX2, posY + Constants.attrsStartY + lineSpacing, 0)
        g.write("\(s[safe: Res.STR_VELOCIDAD] ?? ""):\(uni.defaultSpeed)",
                Constants.attrsStartX3, posY + Constants.attrsStartY, 0)
        g.write("\(s[safe: Res.STR_VISIBILIDAD] ?? ""):\(uni.visibility)",
                Constants.attrsStartX3, posY + Constants.attrsStartY + lineSpacing, 0)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
