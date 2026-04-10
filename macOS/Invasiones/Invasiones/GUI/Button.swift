//
//  Button.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//

import Foundation

struct Button {

    // MARK: - Constants
    enum Constants {
        static let screenEdgeOffset = 15
        static let defaultHeight    = 25
        static let defaultWidth     = 100
    }

    // MARK: - Declarations
    var frame = Frame(width: Constants.defaultWidth, height: Constants.defaultHeight)
    var font:  GameFont?
    var image: Surface? = nil
    var label: Int = 0

    private(set) var isUnderCursor = false

    // MARK: - Initializer
    init(label: Int, font: GameFont? = nil) {
        self.label = label
        self.font  = font ?? ResourceManager.shared.fonts[FontConstants.buttonFont]
    }

    // MARK: - Methods

    mutating func setPosition(x: Int, y: Int, anchor: Int) {
        frame.setPosition(x: x, y: y, anchor: anchor)
    }

    @discardableResult
    mutating func update() -> Int {
        let mx = Int(Mouse.shared.x)
        let my = Int(Mouse.shared.y)
        isUnderCursor = mx > frame.posX && mx < frame.posX + frame.width
                     && my > frame.posY && my < frame.posY + frame.height

        if isUnderCursor && Mouse.shared.pressedButtons.contains(Mouse.Constants.leftButton) {
            Mouse.shared.releaseButton(Mouse.Constants.leftButton)
            return 1
        }
        return 0
    }

    func draw(_ video: Video) {
        let alpha = isUnderCursor ? 250 : Theme.alpha
        video.setColor(isUnderCursor ? Theme.buttonHover : Theme.menus)
        video.fillRoundedRect(frame.posX, frame.posY, frame.width, frame.height, 6, alpha)

        video.setFont(font, Theme.text)
        video.write(
            label,
            frame.posX - Video.width  / 2 + frame.width  / 2,
            frame.posY - Video.height / 2 + frame.height / 2,
            Surface.centerHorizontal | Surface.centerVertical
        )
    }
}
