//
//  LogoState.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of EstadoLogo.cs — logo splash screen with fade-in before transitioning to the menu.
//

import Foundation

class LogoState: State {

    // MARK: - Constants
    private let LOGO_INICIO_CNT = 20
    private let LOGO_TIEMPO_CNT = 70

    // MARK: - Declarations
    private var m_logo:          Surface?
    private var m_alpha: Int = 10

    // MARK: - Initializer
    override init(_ sm: StateMachine) {
        super.init(sm)
        m_count = 0
    }

    // MARK: - Methods

    override func start() {}

    override func update() {
        if m_count == 0 {
            m_logo = ResourceManager.shared.getAlphaImage(Res.IMG_LOGO)
            m_alpha = 10
        } else if m_count > LOGO_INICIO_CNT + LOGO_TIEMPO_CNT {
            stateMachine.setNextState(.MAIN_MENU)
        }
        m_count += 1
    }

    override func draw(_ g: Video) {
        g.fillRect(Definitions.COLOR_BLACK)

        if m_count > LOGO_INICIO_CNT && m_count < LOGO_TIEMPO_CNT {
            if m_alpha < 255 - 10 {
                m_alpha += 10
            }
            g.draw(m_logo, 0, 0, m_alpha, Surface.centerHorizontal | Surface.centerVertical)
        }
    }

    override func exit() {
        m_logo = nil
    }
}
