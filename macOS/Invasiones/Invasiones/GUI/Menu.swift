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
    static let MAX_ITEM_COUNT    = 15
    static let ITEM_VISIBLE          = 1 << 1
    static let ITEM_HIDDEN        = 1 << 2
    static let ITEM_HOVER = 1 << 3
    static let ITEM_SELECTED     = 1 << 4

    // MARK: - Declarations
    private var m_items:              [Int]
    private var m_itemCount:    Int = 0
    private var m_buttonWidth:         Int = 160
    private var m_buttonHeight:          Int = 26
    private var m_lineSpacing: Int = 1
    private var m_originalY:  Int
    private var m_originalX:  Int
    private var m_anchor:              Int

    // MARK: - Initializer
    init(image: Surface?, itemCount: Int, x: Int, y: Int, anchor: Int) {
        m_items             = Array(repeating: 0, count: Menu.MAX_ITEM_COUNT)
        m_originalX = x
        m_originalY = y
        m_anchor             = anchor
        super.init()

        m_image = image
        if itemCount == 3 {
            m_image = ResourceManager.shared.getAlphaImage(Res.IMG_MENU_3)
        } else if itemCount == 2 {
            m_image = ResourceManager.shared.getAlphaImage(Res.IMG_MENU_2)
        }
    }

    // MARK: - Methods

    override func draw(_ g: Video) {
        if let img = m_image {
            g.draw(img, m_x, m_y - 6, 0)
        }

        var y = m_y
        for i in 0..<m_itemCount {
            let flags = (m_items[i] & 0xFF00) >> 8
            if flags != Menu.ITEM_HIDDEN {
                if (flags & Menu.ITEM_HOVER) != 0 {
                    g.setColor(Definitions.COLOR_BLACK)
                    g.fillRect(m_x + 2, y, m_buttonWidth, m_buttonHeight)
                }
                g.setFont(m_font, Definitions.GUI_COLOR_TEXT)
                g.write(m_items[i] & 0xFF,
                           m_x - (Video.width >> 1) + (m_buttonWidth >> 1),
                           y   - (Video.height  >> 1) + (m_buttonHeight  >> 1),
                           Surface.centerHorizontal | Surface.centerVertical)
                y += m_lineSpacing + m_buttonHeight
            }
        }
    }

    @discardableResult
    override func update() -> Int {
        var itemSeleccionado = -1
        var y = m_y

        for i in 0..<m_itemCount {
            let flags = (m_items[i] & 0xFF00) >> 8
            if flags != Menu.ITEM_HIDDEN {
                let mx = Int(Mouse.shared.X)
                let my = Int(Mouse.shared.Y)
                if mx > m_x && mx < m_x + m_buttonWidth && my > y && my < y + m_buttonHeight {
                    m_items[i] |= (Menu.ITEM_HOVER << 8)
                    if Mouse.shared.pressedButtons.contains(Mouse.BUTTON_LEFT) {
                        m_items[i] |= (Menu.ITEM_SELECTED << 8)
                        itemSeleccionado = i
                    }
                } else {
                    m_items[i] &= ~(Menu.ITEM_HOVER << 8)
                }
                y += m_lineSpacing + m_buttonHeight
            }
        }

        return itemSeleccionado
    }

    override func setPosition(_ x: Int, _ y: Int, _ anchor: Int) {
        m_originalX = x
        m_x = x
        m_originalY = y
        m_y = y
        m_anchor = anchor

        if (m_anchor & Surface.centerHorizontal) != 0 {
            m_x = (Video.width >> 1) - (m_buttonWidth >> 1) + m_originalX
        }
        if (m_anchor & Surface.centerVertical) != 0 {
            m_y = (Video.height >> 1) + m_originalY
                - (((m_buttonHeight + m_lineSpacing) * m_itemCount
                    - m_lineSpacing) >> 1)
        }
    }

    @discardableResult
    func addItem(_ index: Int, _ stringId: Int, _ flag: Int) -> Bool {
        guard index <= Menu.MAX_ITEM_COUNT - 1 else { return false }

        if m_itemCount == index {
            m_itemCount += 1
        }
        m_items[index] = (flag << 8) | (stringId & 0xFF)

        if (m_anchor & Surface.centerHorizontal) != 0 {
            m_x = (Video.width >> 1) - (m_buttonWidth >> 1) + m_originalX
        }
        if (m_anchor & Surface.centerVertical) != 0 {
            m_y = (Video.height >> 1) + m_originalY
                - (((m_buttonHeight + m_lineSpacing) * m_itemCount
                    - m_lineSpacing) >> 1)
        }

        m_height  = m_image?.height  ?? 0
        m_width = m_image?.width ?? 0

        return true
    }

    func setImage(_ sup: Surface?) {
        m_image = sup
    }

    func setFont(_ font: GameFont?) {
        m_font = font
    }
}
