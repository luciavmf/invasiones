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
    enum SELECCION: Int {
        case NINGUNO   = -1
        case IZQUIERDO =  0
        case DERECHO   =  1
    }

    // MARK: - Declarations
    private var m_leftButton: Button
    private var m_rightButton: Button

    // MARK: - Initializer
    init(_ label: Int, _ boton1: Int, _ boton2: Int) {
        m_leftButton = Button(label: boton1, font: nil)
        m_leftButton.setPosition(0, 0, 0)
        m_rightButton = Button(label: boton2, font: nil)
        m_rightButton.setPosition(200, 200, 0)
        super.init()
        m_label = label
        m_width   = Definitions.CONFIRMATION_WIDTH
        m_height    = Definitions.CONFIRMATION_HEIGHT
    }

    // MARK: - GUIBox overrides

    override func setPosition(_ x: Int, _ y: Int, _ anchor: Int) {
        m_x = x
        m_y = y
        if (anchor & Surface.centerHorizontal) != 0 { m_x += (Video.width >> 1) - (m_width >> 1) }
        if (anchor & Surface.centerVertical) != 0 { m_y += (Video.height  >> 1) - (m_height  >> 1) }

        m_leftButton.setPosition(
            m_x + Button.OFFSET_LIMITE_PANTALLA,
            m_y + m_height - m_leftButton.height - Button.OFFSET_LIMITE_PANTALLA,
            0
        )

        m_rightButton.setPosition(
            m_x + m_width - m_rightButton.width - Button.OFFSET_LIMITE_PANTALLA,
            m_y + m_height  - m_rightButton.height  - Button.OFFSET_LIMITE_PANTALLA,
            0
        )
    }

    @discardableResult
    override func update() -> Int {
        if m_leftButton.update() != 0 { return SELECCION.IZQUIERDO.rawValue }
        if m_rightButton.update() != 0 { return SELECCION.DERECHO.rawValue   }
        return SELECCION.NINGUNO.rawValue
    }

    override func draw(_ g: Video) {
        g.setColor(Definitions.GUI_COLOR_MENUS)
        g.fillRect(m_x, m_y, m_width, m_height, Definitions.CONFIRMATION_ALPHA)

        g.setFont(
            ResourceManager.shared.fonts[Definitions.FONT_MENU],
            Definitions.GUI_COLOR_TEXT
        )
        g.write(
            m_label,
            m_x - (Video.width >> 1) + (m_width >> 1),
            m_y + m_height / 5,
            Surface.centerHorizontal
        )

        m_leftButton.draw(g)
        m_rightButton.draw(g)
    }
}
