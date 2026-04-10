//
//  ConfirmationMenu.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of MenuDeConfirmacion.cs — dialog box with two buttons.
//

import Foundation

class ConfirmationMenu {

    // MARK: - Enum
    enum Selection: Int {
        case none  = -1
        case left  =  0
        case right =  1
    }

    enum Constants {
        static let alpha         = 128
        static let defaultWidth  = 350
        static let defaultHeight = 150
    }

    // MARK: - Declarations
    var frame = Frame(width: Constants.defaultWidth, height: Constants.defaultHeight)
    var label: Int

    private var leftButton:  Button
    private var rightButton: Button

    // MARK: - Initializer
    init(_ lbl: Int, _ boton1: Int, _ boton2: Int) {
        label = lbl
        leftButton  = Button(label: boton1, font: nil)
        leftButton.setPosition(x: 0, y: 0, anchor: 0)
        rightButton = Button(label: boton2, font: nil)
        rightButton.setPosition(x: 200, y: 200, anchor: 0)
    }

    // MARK: - Methods

    func setPosition(x: Int, y: Int, anchor: Int) {
        frame.posX = x
        frame.posY = y
        if (anchor & Surface.centerHorizontal) != 0 { frame.posX += (Video.width  >> 1) - (frame.width  >> 1) }
        if (anchor & Surface.centerVertical)   != 0 { frame.posY += (Video.height >> 1) - (frame.height >> 1) }

        leftButton.setPosition(
            x: frame.posX + Button.Constants.screenEdgeOffset,
            y: frame.posY + frame.height - leftButton.frame.height - Button.Constants.screenEdgeOffset,
            anchor: 0
        )
        rightButton.setPosition(
            x: frame.posX + frame.width - rightButton.frame.width - Button.Constants.screenEdgeOffset,
            y: frame.posY + frame.height - rightButton.frame.height - Button.Constants.screenEdgeOffset,
            anchor: 0
        )
    }

    @discardableResult
    func update() -> Int {
        if leftButton.update()  != 0 { return Selection.left.rawValue  }
        if rightButton.update() != 0 { return Selection.right.rawValue }
        return Selection.none.rawValue
    }

    func draw(_ video: Video) {
        video.setColor(Theme.menus)
        video.fillRect(frame.posX, frame.posY, frame.width, frame.height, Constants.alpha)

        video.setFont(
            ResourceManager.shared.fonts[FontConstants.menuFont],
            Theme.text
        )
        video.write(
            label,
            frame.posX - (Video.width >> 1) + (frame.width >> 1),
            frame.posY + frame.height / 5,
            Surface.centerHorizontal
        )

        leftButton.draw(video)
        rightButton.draw(video)
    }
}
