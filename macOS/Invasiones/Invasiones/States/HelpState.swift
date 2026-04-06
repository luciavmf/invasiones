//
//  HelpState.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of HelpState.cs — help/tutorial screens with animations.
//

import Foundation

class HelpState: State {

    // MARK: - Sub-states
    private enum SUBESTADO: Int {
        case SELECCIONAR = 0, MOVE, ATTACK, OBJETIVO, SCROLL, HUD, HEAL, TIPS, GANAR
        static let TOTAL = 9
    }

    // MARK: - Declarations
    private var m_substate:        SUBESTADO = .SELECCIONAR
    private var m_backButton:       Button?
    private var m_nextButton:         Button?
    private var m_currentScreenshot: Animation?

    // MARK: - Methods

    override func start() {
        m_background = ResourceManager.shared.getImage(Res.IMG_FONDO)

        let fnt = ResourceManager.shared.fonts[Definitions.FNT.SANS18.rawValue]

        m_button = Button(label: Res.STR_BOTON_MENU, font: fnt)
        m_button?.setPosition(
            Video.width - (m_button?.width ?? 0) - Button.OFFSET_LIMITE_PANTALLA,
            Video.height  - (m_button?.height  ?? 0) - Button.OFFSET_LIMITE_PANTALLA, 0)

        m_nextButton = Button(label: Res.STR_SIGUIENTE, font: fnt)
        m_nextButton?.setPosition(
            Video.width - (m_nextButton?.width ?? 0) - Button.OFFSET_LIMITE_PANTALLA,
            Video.height  - (m_nextButton?.height  ?? 0) - Button.OFFSET_LIMITE_PANTALLA, 0)

        m_backButton = Button(label: Res.STR_ATRAS, font: fnt)
        m_backButton?.setPosition(
            Video.width - (m_nextButton?.width ?? 0) * 2 - Button.OFFSET_LIMITE_PANTALLA,
            Video.height  - (m_nextButton?.height  ?? 0) - Button.OFFSET_LIMITE_PANTALLA, 0)

        m_substate = .SELECCIONAR
        loadScreenshot(m_substate)
    }

    override func update() {
        if m_button?.update() != 0 {
            let next = m_substate.rawValue + 1
            if next > SUBESTADO.GANAR.rawValue {
                stateMachine.setNextState(.MAIN_MENU)
            } else if let next = SUBESTADO(rawValue: next) {
                m_substate = next
                loadScreenshot(next)
            }
        }

        if m_backButton?.update() != 0, m_substate != .SELECCIONAR {
            let prev = m_substate.rawValue - 1
            if let prev = SUBESTADO(rawValue: prev) {
                m_substate = prev
                loadScreenshot(prev)
            }
        }

        m_currentScreenshot?.update()
    }

    override func draw(_ g: Video) {
        g.draw(m_background, 0, 0, 0)

        g.setFont(ResourceManager.shared.fonts[Definitions.FONT_TITLE],
                       Definitions.COLOR_TITLE)
        g.write(Res.STR_MENU_AYUDA, 0, Definitions.TITLE_Y, Surface.centerHorizontal)

        if m_substate.rawValue < SUBESTADO.TOTAL {
            g.setFont(ResourceManager.shared.fonts[Definitions.FONT_HELP_TITLE],
                           Definitions.GUI_COLOR_TEXT)
            g.write(Res.STR_MENU_AYUDA_TEXTO_SELECCIONAR_01 + m_substate.rawValue * 2,
                       0, Definitions.HELP_ITEM_Y, Surface.centerHorizontal)

            g.setFont(ResourceManager.shared.fonts[Definitions.FONT_HELP],
                           Definitions.GUI_COLOR_TEXT)
            g.write(Res.STR_MENU_AYUDA_TEXTO_SELECCIONAR_02 + m_substate.rawValue * 2,
                       0, Definitions.HELP_TEXT_Y, Surface.centerHorizontal)
        }

        m_currentScreenshot?.draw(g, 0, 150, Surface.centerHorizontal | Surface.centerVertical)

        if m_substate != .SELECCIONAR { m_backButton?.draw(g) }
        if m_substate != .GANAR {
            m_nextButton?.draw(g)
        } else {
            m_button?.draw(g)
        }
    }

    override func exit() {}

    // MARK: - Private

    private func loadScreenshot(_ sub: SUBESTADO) {
        let animIdx = Res.ANIM_AYUDA_SELECCION + sub.rawValue
        let anims = ResourceManager.shared.animations
        guard animIdx < anims.count, let anim = anims[animIdx] else {
            m_currentScreenshot = nil
            return
        }
        anim.load()
        anim.play()
        anim.loop = true
        m_currentScreenshot = anim
    }
}
