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
    private static let MAX_BLINK       = 40
    private static let MIN_BLINK       = 20

    // MARK: - Declarations
    private var m_tipButton:               Button
    private var m_shouldShowTip:  Bool = false
    private var m_tipCount:              Int  = 0
    private var m_blinkCount:           Int  = 0

    // MARK: - Initializer
    override init() {
        m_tipButton = Button(label: Res.STR_TIP_00, font: nil)
        super.init()

        m_tipButton.setPosition(
            Video.width - m_tipButton.width - 20,
            Video.height  - 90 - m_tipButton.height,
            0)

        m_width = Definitions.TIPS_WIDTH
        m_height  = Definitions.TIPS_HEIGHT

        generateRandomTip()

        m_tipCount              = Tips.INITIAL_TIP_TIME
        m_shouldShowTip  = false
    }

    // MARK: - GUIBox

    override func setPosition(_ x: Int, _ y: Int, _ anchor: Int) {
        m_x = x
        m_y = y
        if (anchor & Surface.centerHorizontal) != 0 { m_x += (Video.width >> 1) - (m_width >> 1) }
        if (anchor & Surface.centerVertical) != 0 { m_y += (Video.height  >> 1) - (m_height  >> 1) }
    }

    @discardableResult
    override func update() -> Int {
        m_blinkCount += 1

        if m_shouldShowTip {
            if m_tipCount <= 0 {
                m_shouldShowTip = false
            }
            if m_blinkCount > Tips.MAX_BLINK {
                m_blinkCount = 0
            }
        } else {
            if Int.random(in: 0..<300) == 99 {
                m_shouldShowTip = true
                m_blinkCount          = 0
                m_tipCount             = Tips.INITIAL_TIP_TIME
                generateRandomTip()
            }
        }

        m_tipButton.update()
        return -1  // SELECCION.NINGUNO
    }

    override func draw(_ g: Video) {
        guard m_shouldShowTip else { return }

        if m_tipButton.isUnderCursor {
            g.setColor(Definitions.GUI_COLOR_MENUS)
            g.fillRect(m_x, m_y, m_width, m_height, Definitions.TIPS_ALPHA)
            g.setFont(
                ResourceManager.shared.fonts[Definitions.FONT_OBJECTIVES_REMINDER],
                Definitions.GUI_COLOR_TEXT)
            g.write(m_label,
                       m_x - (Video.width >> 1) + (m_width >> 1),
                       m_y + m_height / 5,
                       Surface.centerHorizontal)
            m_tipButton.draw(g)
        } else {
            m_tipCount -= 1
            if m_blinkCount > Tips.MIN_BLINK && m_blinkCount < Tips.MAX_BLINK {
                m_tipButton.draw(g)
            }
        }
    }

    // MARK: - Private

    private func generateRandomTip() {
        m_label = Int.random(in: Res.STR_TIP_01..<Res.STR_TIP_23)
    }
}
