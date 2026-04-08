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
    enum Constants {
        static let maxItemCount = 15
        static let itemVisible = 1 << 1
        static let itemHidden = 1 << 2
        static let itemHover = 1 << 3
        static let itemSelected = 1 << 4
    }

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
        items = Array(repeating: 0, count: Constants.maxItemCount)
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

    override func draw(_ video: Video) {
        if let img = image {
            video.draw(img, posX, posY - 6, 0)
        }

        var y = posY
        for i in 0..<itemCount {
            let flags = (items[i] & 0xFF00) >> 8
            if flags != Constants.itemHidden {
                if (flags & Constants.itemHover) != 0 {
                    video.setColor(GameColor.black)
                    video.fillRect(posX + 2, y, buttonWidth, buttonHeight)
                }
                video.setFont(font, UIColors.text)
                video.write(items[i] & 0xFF,
                           posX - (Video.width >> 1) + (buttonWidth >> 1),
                           y   - (Video.height  >> 1) + (buttonHeight  >> 1),
                           Surface.centerHorizontal | Surface.centerVertical)
                y += lineSpacing + buttonHeight
            }
        }
    }

    @discardableResult
    override func update() -> Int {
        var selectedItem = -1
        var y = posY

        for i in 0..<itemCount {
            let flags = (items[i] & 0xFF00) >> 8
            if flags != Constants.itemHidden {
                let mx = Int(Mouse.shared.x)
                let my = Int(Mouse.shared.y)
                if mx > posX && mx < posX + buttonWidth && my > y && my < y + buttonHeight {
                    items[i] |= (Constants.itemHover << 8)
                    if Mouse.shared.pressedButtons.contains(Mouse.Constants.leftButton) {
                        items[i] |= (Constants.itemSelected << 8)
                        selectedItem = i
                    }
                } else {
                    items[i] &= ~(Constants.itemHover << 8)
                }
                y += lineSpacing + buttonHeight
            }
        }

        return selectedItem
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
        guard index <= Constants.maxItemCount - 1 else { return false }

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
