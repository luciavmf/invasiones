//
//  ConfirmationMenu.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of MenuDeConfirmacion.cs — dialog box with two buttons.
//

import Foundation

class ConfirmationMenu: GUIBox {

    // MARK: - Enum
    enum Selection: Int {
        case none = -1
        case left =  0
        case right =  1
    }

    // MARK: - Declarations
    private var leftButton: Button
    private var rightButton: Button

    // MARK: - Initializer
    init(_ lbl: Int, _ boton1: Int, _ boton2: Int) {
        leftButton = Button(label: boton1, font: nil)
        leftButton.setPosition(x: 0, y: 0, anchor: 0)
        rightButton = Button(label: boton2, font: nil)
        rightButton.setPosition(x: 200, y: 200, anchor: 0)
        super.init()
        label = lbl
        width = Definitions.CONFIRMATION_WIDTH
        height = Definitions.CONFIRMATION_HEIGHT
    }

    // MARK: - GUIBox overrides

    override func setPosition(x: Int, y: Int, anchor: Int) {
        posX = x
        posY = y
        if (anchor & Surface.centerHorizontal) != 0 { posX += (Video.width >> 1) - (width >> 1) }
        if (anchor & Surface.centerVertical) != 0 { posY += (Video.height >> 1) - (height >> 1) }

        leftButton.setPosition(
            x: posX + Button.OFFSET_LIMITE_PANTALLA,
            y: posY + height - leftButton.height - Button.OFFSET_LIMITE_PANTALLA,
            anchor: 0
        )

        rightButton.setPosition(
            x: posX + width - rightButton.width - Button.OFFSET_LIMITE_PANTALLA,
            y: posY + height  - rightButton.height  - Button.OFFSET_LIMITE_PANTALLA,
            anchor: 0
        )
    }

    @discardableResult
    override func update() -> Int {
        if leftButton.update() != 0 { return Selection.left.rawValue }
        if rightButton.update() != 0 { return Selection.right.rawValue }
        return Selection.none.rawValue
    }

    override func draw(_ g: Video) {
        g.setColor(Definitions.GUI_COLOR_MENUS)
        g.fillRect(posX, posY, width, height, Definitions.CONFIRMATION_ALPHA)

        g.setFont(
            ResourceManager.shared.fonts[Definitions.FONT_MENU],
            Definitions.GUI_COLOR_TEXT
        )
        g.write(
            label,
            posX - (Video.width >> 1) + (width >> 1),
            posY + height / 5,
            Surface.centerHorizontal
        )

        leftButton.draw(g)
        rightButton.draw(g)
    }
}
