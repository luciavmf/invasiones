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
    static let OFFSET_LIMITE_PANTALLA = 15
    static let ALTO                   = 25
    static let ANCHO                  = 100
    static let ANCHO_MINIMO           = 10
    static let ALTO_MINIMO            = 10

    // MARK: - Declarations
    private var m_selectedImage:       Surface?
    private(set) var isUnderCursor = false

    // MARK: - Initializer
    init(label: Int, font: GameFont?) {
        super.init()

        m_height  = Button.ALTO
        m_width = Button.ANCHO

        m_image    = ResourceManager.shared.getAlphaImage(Res.IMG_BOTON)
        m_height      = m_image?.height  ?? Button.ALTO
        m_width     = m_image?.width ?? Button.ANCHO
        m_selectedImage = ResourceManager.shared.getAlphaImage(Res.IMG_BOTON_SELECCION)
        m_font    = font ?? ResourceManager.shared.fonts[Definitions.FONT_BUTTON]
        m_label   = label
    }

    // MARK: - Methods

    override func setPosition(_ x: Int, _ y: Int, _ anchor: Int) {
        m_x = x
        m_y = y
        if (anchor & Surface.centerVertical) != 0 { m_y += (Video.height  >> 1) - (m_height  >> 1) }
        if (anchor & Surface.centerHorizontal) != 0 { m_x += (Video.width >> 1) - (m_width >> 1) }
    }

    @discardableResult
    override func update() -> Int {
        let mx = Int(Mouse.shared.X)
        let my = Int(Mouse.shared.Y)
        isUnderCursor = mx > m_x && mx < m_x + m_width && my > m_y && my < m_y + m_height

        if isUnderCursor && Mouse.shared.pressedButtons.contains(Mouse.BUTTON_LEFT) {
            Mouse.shared.releaseButton(Mouse.BUTTON_LEFT)
            return 1
        }
        return 0
    }

    override func draw(_ g: Video) {
        if isUnderCursor {
            if m_selectedImage != nil {
                g.draw(m_selectedImage, m_x, m_y, 0)
            } else {
                g.setColor(Definitions.GUI_COLOR_SELECTION)
                g.fillRect(m_x, m_y, m_width, m_height, Definitions.GUI_ALPHA)
            }
        } else {
            if m_image != nil {
                g.draw(m_image, m_x, m_y, 0)
            } else {
                g.setColor(Definitions.GUI_COLOR_MENUS)
                g.fillRect(m_x, m_y, m_width, m_height, Definitions.GUI_ALPHA)
            }
        }

        g.setFont(m_font, Definitions.GUI_COLOR_TEXT)
        g.write(m_label,
                   m_x - Video.width / 2 + m_width / 2,
                   m_y - Video.height  / 2 + m_height  / 2,
                   Surface.centerHorizontal | Surface.centerVertical)
    }

    func setHeight(_ height: Int) {
        if m_image == nil { m_height = height }
    }

    func setWidth(_ width: Int) {
        if m_image == nil { m_width = width }
    }
}
