//
//  Menu.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Menu.cs — vertical menu with mouse-selectable items.
//

import Foundation

class Menu: GUIBox {

    // MARK: - Constants
    static let MAX_ITEM_COUNT = 15
    static let ITEM_VISIBLE = 1 << 1
    static let ITEM_HIDDEN = 1 << 2
    static let ITEM_HOVER = 1 << 3
    static let ITEM_SELECTED = 1 << 4

    // MARK: - Declarations
    private var items: [Int]
    private var itemCount: Int = 0
    private var buttonWidth: Int = 160
    private var buttonHeight: Int = 26
    private var lineSpacing: Int = 1
    private var originalY: Int
    private var originalX: Int
    private var anchor: Int

    // MARK: - Initializer
    init(image img: Surface?, itemCount: Int, x: Int, y: Int, anchor anch: Int) {
        items = Array(repeating: 0, count: Menu.MAX_ITEM_COUNT)
        originalX = x
        originalY = y
        anchor = anch
        super.init()

        self.image = img
        if itemCount == 3 {
            self.image = ResourceManager.shared.getAlphaImage(Res.IMG_MENU_3)
        } else if itemCount == 2 {
            self.image = ResourceManager.shared.getAlphaImage(Res.IMG_MENU_2)
        }
    }

    // MARK: - Methods

    override func draw(_ g: Video) {
        if let img = image {
            g.draw(img, posX, posY - 6, 0)
        }

        var y = posY
        for i in 0..<itemCount {
            let flags = (items[i] & 0xFF00) >> 8
            if flags != Menu.ITEM_HIDDEN {
                if (flags & Menu.ITEM_HOVER) != 0 {
                    g.setColor(Definitions.COLOR_BLACK)
                    g.fillRect(posX + 2, y, buttonWidth, buttonHeight)
                }
                g.setFont(font, Definitions.GUI_COLOR_TEXT)
                g.write(items[i] & 0xFF,
                           posX - (Video.width >> 1) + (buttonWidth >> 1),
                           y   - (Video.height  >> 1) + (buttonHeight  >> 1),
                           Surface.centerHorizontal | Surface.centerVertical)
                y += lineSpacing + buttonHeight
            }
        }
    }

    @discardableResult
    override func update() -> Int {
        var itemSeleccionado = -1
        var y = posY

        for i in 0..<itemCount {
            let flags = (items[i] & 0xFF00) >> 8
            if flags != Menu.ITEM_HIDDEN {
                let mx = Int(Mouse.shared.X)
                let my = Int(Mouse.shared.Y)
                if mx > posX && mx < posX + buttonWidth && my > y && my < y + buttonHeight {
                    items[i] |= (Menu.ITEM_HOVER << 8)
                    if Mouse.shared.pressedButtons.contains(Mouse.BUTTON_LEFT) {
                        items[i] |= (Menu.ITEM_SELECTED << 8)
                        itemSeleccionado = i
                    }
                } else {
                    items[i] &= ~(Menu.ITEM_HOVER << 8)
                }
                y += lineSpacing + buttonHeight
            }
        }

        return itemSeleccionado
    }

    override func setPosition(x: Int, y: Int, anchor anch: Int) {
        originalX = x
        posX = x
        originalY = y
        posY = y
        anchor = anch

        if (anchor & Surface.centerHorizontal) != 0 {
            posX = (Video.width >> 1) - (buttonWidth >> 1) + originalX
        }
        if (anchor & Surface.centerVertical) != 0 {
            posY = (Video.height >> 1) + originalY
                - (((buttonHeight + lineSpacing) * itemCount
                    - lineSpacing) >> 1)
        }
    }

    @discardableResult
    func addItem(index: Int, stringId: Int, flag: Int) -> Bool {
        guard index <= Menu.MAX_ITEM_COUNT - 1 else { return false }

        if itemCount == index {
            itemCount += 1
        }
        items[index] = (flag << 8) | (stringId & 0xFF)

        if (anchor & Surface.centerHorizontal) != 0 {
            posX = (Video.width >> 1) - (buttonWidth >> 1) + originalX
        }
        if (anchor & Surface.centerVertical) != 0 {
            posY = (Video.height >> 1) + originalY
                - (((buttonHeight + lineSpacing) * itemCount
                    - lineSpacing) >> 1)
        }

        height = image?.height ?? 0
        width = image?.width ?? 0

        return true
    }

}
