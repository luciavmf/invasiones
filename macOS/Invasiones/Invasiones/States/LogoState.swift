//
//  LogoState.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of EstadoLogo.cs — logo splash screen with fade-in before transitioning to the menu.
//

import Foundation

/// Displays the studio logo with a fade-in effect and then transitions to the main menu.
/// Resources are loaded on the first update tick while the black screen is shown.
class LogoState: State {

    // MARK: - Constants
    /// Number of ticks before the logo starts fading in.
    private let logoStartTick = 20
    /// Number of ticks the logo is displayed (fade-in window).
    private let logoEndTick = 70

    // MARK: - Declarations
    private var logo: Surface?
    /// Current alpha value used for the fade-in (0–255).
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
        } else if count > logoStartTick + logoEndTick {
            stateMachine.setNextState(.mainMenu)
        }
        count += 1
    }

    override func draw(_ video: Video) {
        video.fillRect(GameColor.black)

        if count > logoStartTick && count < logoEndTick {
            if alpha < 255 - 10 {
                alpha += 10
            }
            video.draw(logo, 0, 0, alpha, Surface.centerHorizontal | Surface.centerVertical)
        }
    }

    override func exit() {
        logo = nil
    }
}
