//
//  Tips.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Tips.cs — floating window with random gameplay tips.
//

import Foundation

class Tips: GUIBox {

    // MARK: - Constants
    private static let INITIAL_TIP_TIME = 250
    private static let MAX_BLINK = 40
    private static let MIN_BLINK = 20

    // MARK: - Declarations
    private var tipButton: Button
    private var shouldShowTip: Bool = false
    private var tipCount: Int = 0
    private var blinkCount: Int = 0

    // MARK: - Initializer
    override init() {
        tipButton = Button(label: Res.STR_TIP_00, font: nil)
        super.init()

        tipButton.setPosition(
            x: Video.width - tipButton.width - 20,
            y: Video.height  - 90 - tipButton.height,
            anchor: 0)

        width = Definitions.TIPS_WIDTH
        height = Definitions.TIPS_HEIGHT

        generateRandomTip()

        tipCount = Tips.INITIAL_TIP_TIME
        shouldShowTip = false
    }

    // MARK: - GUIBox

    override func setPosition(x: Int, y: Int, anchor: Int) {
        posX = x
        posY = y
        if (anchor & Surface.centerHorizontal) != 0 { posX += (Video.width >> 1) - (width >> 1) }
        if (anchor & Surface.centerVertical) != 0 { posY += (Video.height >> 1) - (height >> 1) }
    }

    @discardableResult
    override func update() -> Int {
        blinkCount += 1

        if shouldShowTip {
            if tipCount <= 0 {
                shouldShowTip = false
            }
            if blinkCount > Tips.MAX_BLINK {
                blinkCount = 0
            }
        } else {
            if Int.random(in: 0..<300) == 99 {
                shouldShowTip = true
                blinkCount = 0
                tipCount = Tips.INITIAL_TIP_TIME
                generateRandomTip()
            }
        }

        tipButton.update()
        return -1  // SELECCION.NINGUNO
    }

    override func draw(_ g: Video) {
        guard shouldShowTip else { return }

        if tipButton.isUnderCursor {
            g.setColor(Definitions.GUI_COLOR_MENUS)
            g.fillRect(posX, posY, width, height, Definitions.TIPS_ALPHA)
            g.setFont(
                ResourceManager.shared.fonts[Definitions.FONT_OBJECTIVES_REMINDER],
                Definitions.GUI_COLOR_TEXT)
            g.write(label,
                       posX - (Video.width >> 1) + (width >> 1),
                       posY + height / 5,
                       Surface.centerHorizontal)
            tipButton.draw(g)
        } else {
            tipCount -= 1
            if blinkCount > Tips.MIN_BLINK && blinkCount < Tips.MAX_BLINK {
                tipButton.draw(g)
            }
        }
    }

    // MARK: - Private

    private func generateRandomTip() {
        label = Int.random(in: Res.STR_TIP_01..<Res.STR_TIP_23)
    }
}
