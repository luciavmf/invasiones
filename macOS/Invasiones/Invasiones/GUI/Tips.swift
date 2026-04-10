//
//  Tips.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Tips.cs — floating window with random gameplay tips.
//

import Foundation

class Tips {

    // MARK: - Constants
    private enum Constants {
        static let initialTipTime = 250
        static let maxBlink       = 40
        static let minBlink       = 20
        static let alpha          = 100
        static let defaultWidth   = 450
        static let defaultHeight  = 100
    }

    // MARK: - Declarations
    var frame = Frame(width: Constants.defaultWidth, height: Constants.defaultHeight)

    private var tipButton: Button
    private var tipText: String = ""
    private var shouldShowTip: Bool = false
    private var tipCount: Int = 0
    private var blinkCount: Int = 0

    // MARK: - Initializer
    init() {
        tipButton = Button(label: Res.STR_TIP_00, font: nil)
        tipButton.setPosition(
            x: Video.width  - tipButton.frame.width  - 20,
            y: Video.height - 90 - tipButton.frame.height,
            anchor: 0
        )

        generateRandomTip()
        tipCount = Constants.initialTipTime
        shouldShowTip = false
    }

    // MARK: - Methods

    func setPosition(x: Int, y: Int, anchor: Int) {
        frame.posX = x
        frame.posY = y
        if (anchor & Surface.centerHorizontal) != 0 { frame.posX += (Video.width  >> 1) - (frame.width  >> 1) }
        if (anchor & Surface.centerVertical)   != 0 { frame.posY += (Video.height >> 1) - (frame.height >> 1) }
    }

    @discardableResult
    func update() -> Int {
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
        return -1
    }

    func draw(_ video: Video) {
        guard shouldShowTip else { return }

        if tipButton.isUnderCursor {
            video.setColor(Theme.menus)
            video.fillRect(frame.posX, frame.posY, frame.width, frame.height, Constants.alpha)
            video.setFont(
                ResourceManager.shared.fonts[FontConstants.objectivesReminderFont],
                Theme.text
            )
            video.write(
                tipText,
                frame.posX - (Video.width >> 1) + (frame.width >> 1),
                frame.posY + frame.height / 5,
                Surface.centerHorizontal
            )
            tipButton.draw(video)
        } else {
            tipCount -= 1
            if blinkCount > Constants.minBlink && blinkCount < Constants.maxBlink {
                tipButton.draw(video)
            }
        }
    }

    // MARK: - Private

    private func generateRandomTip() {
        tipText = GameText.tips.randomElement() ?? ""
    }
}
