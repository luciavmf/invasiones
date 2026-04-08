//
//  Button.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Boton.cs — button with background image and centered text.
//

import Foundation

class Button: GUIBox {

    // MARK: - Constants
    enum Constants {
        static let screenEdgeOffset = 15
        static let defaultHeight = 25
        static let defaultWidth = 100
        static let minWidth = 10
        static let minHeight = 10
    }

    // MARK: - Declarations
    private var selectedImage: Surface?
    private(set) var isUnderCursor = false

    // MARK: - Initializer
    init(label: Int, font: GameFont?) {
        super.init()

        self.height = Constants.defaultHeight
        self.width = Constants.defaultWidth

        self.image = ResourceManager.shared.getAlphaImage(Res.IMG_BOTON)
        self.height = self.image?.height ?? Constants.defaultHeight
        self.width = self.image?.width ?? Constants.defaultWidth
        selectedImage = ResourceManager.shared.getAlphaImage(Res.IMG_BOTON_SELECCION)
        self.font = font ?? ResourceManager.shared.fonts[FontConstants.buttonFont]
        self.label = label
    }

    // MARK: - Methods

    override func setPosition(x: Int, y: Int, anchor: Int) {
        posX = x
        posY = y
        if (anchor & Surface.centerVertical) != 0 { posY += (Video.height >> 1) - (height >> 1) }
        if (anchor & Surface.centerHorizontal) != 0 { posX += (Video.width >> 1) - (width >> 1) }
    }

    @discardableResult
    override func update() -> Int {
        let mx = Int(Mouse.shared.X)
        let my = Int(Mouse.shared.Y)
        isUnderCursor = mx > posX && mx < posX + width && my > posY && my < posY + height

        if isUnderCursor && Mouse.shared.pressedButtons.contains(Mouse.Constants.leftButton) {
            Mouse.shared.releaseButton(Mouse.Constants.leftButton)
            return 1
        }
        return 0
    }

    override func draw(_ g: Video) {
        if isUnderCursor {
            if selectedImage != nil {
                g.draw(selectedImage, posX, posY, 0)
            } else {
                g.setColor(UIColors.selection)
                g.fillRect(posX, posY, width, height, UIColors.alpha)
            }
        } else {
            if image != nil {
                g.draw(image, posX, posY, 0)
            } else {
                g.setColor(UIColors.menus)
                g.fillRect(posX, posY, width, height, UIColors.alpha)
            }
        }

        g.setFont(font, UIColors.text)
        g.write(label,
                   posX - Video.width / 2 + width / 2,
                   posY - Video.height  / 2 + height  / 2,
                   Surface.centerHorizontal | Surface.centerVertical)
    }

    func setHeight(_ h: Int) {
        if image == nil { height = h }
    }

    func setWidth(_ w: Int) {
        if image == nil { width = w }
    }
}
