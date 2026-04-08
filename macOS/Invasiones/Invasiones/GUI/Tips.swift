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
    private enum Constants {
        static let initialTipTime = 250
        static let maxBlink = 40
        static let minBlink = 20
        static let alpha = 100
        static let defaultWidth = 450
        static let defaultHeight = 100
    }

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

        width = Constants.defaultWidth
        height = Constants.defaultHeight

        generateRandomTip()

        tipCount = Constants.initialTipTime
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
            if blinkCount > Constants.maxBlink {
                blinkCount = 0
            }
        } else {
            if Int.random(in: 0..<300) == 99 {
                shouldShowTip = true
                blinkCount = 0
                tipCount = Constants.initialTipTime
                generateRandomTip()
            }
        }

        tipButton.update()
        return -1  // SELECCION.NINGUNO
    }

    override func draw(_ g: Video) {
        guard shouldShowTip else { return }

        if tipButton.isUnderCursor {
            g.setColor(UIColors.menus)
            g.fillRect(posX, posY, width, height, Constants.alpha)
            g.setFont(
                ResourceManager.shared.fonts[FontConstants.objectivesReminderFont],
                UIColors.text)
            g.write(label,
                       posX - (Video.width >> 1) + (width >> 1),
                       posY + height / 5,
                       Surface.centerHorizontal)
            tipButton.draw(g)
        } else {
            tipCount -= 1
            if blinkCount > Constants.minBlink && blinkCount < Constants.maxBlink {
                tipButton.draw(g)
            }
        }
    }

    // MARK: - Private

    private func generateRandomTip() {
        label = Int.random(in: Res.STR_TIP_01..<Res.STR_TIP_23)
    }
}
