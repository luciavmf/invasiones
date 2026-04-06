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
    private var logo: Surface?
    private var alpha: Int = 10

    // MARK: - Initializer
    override init(_ sm: StateMachine) {
        super.init(sm)
        count = 0
    }

    // MARK: - Methods

    override func start() {}

    override func update() {
        if count == 0 {
            logo = ResourceManager.shared.getAlphaImage(Res.IMG_LOGO)
            alpha = 10
        } else if count > LOGO_INICIO_CNT + LOGO_TIEMPO_CNT {
            stateMachine.setNextState(.MAIN_MENU)
        }
        count += 1
    }

    override func draw(_ g: Video) {
        g.fillRect(Definitions.COLOR_BLACK)

        if count > LOGO_INICIO_CNT && count < LOGO_TIEMPO_CNT {
            if alpha < 255 - 10 {
                alpha += 10
            }
            g.draw(logo, 0, 0, alpha, Surface.centerHorizontal | Surface.centerVertical)
        }
    }

    override func exit() {
        logo = nil
    }
}
