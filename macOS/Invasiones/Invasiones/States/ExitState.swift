//
//  ExitState.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of EstadoSalir.cs — exit confirmation dialog.
//

import Foundation

class ExitState: State {

    private var confirmMenu: ConfirmationMenu?

    override func start() {
        background = ResourceManager.shared.getImage(Res.IMG_SPLASH)
        confirmMenu = ConfirmationMenu(Res.STR_CONFIRMACION_SALIR, Res.STR_NO, Res.STR_SI)
        confirmMenu?.setPosition(x: 0, y: 0, anchor: Surface.centerVertical | Surface.centerHorizontal)
    }

    override func update() {
        guard let result = confirmMenu?.update() else { return }
        if result == ConfirmationMenu.Selection.right.rawValue {
            stateMachine.setState(.end)
        }
        if result == ConfirmationMenu.Selection.left.rawValue {
            stateMachine.setNextState(.mainMenu)
        }
    }

    override func draw(_ video: Video) {
        video.draw(background, 0, 0, 0)
        confirmMenu?.draw(video)
    }

    override func exit() {
        confirmMenu = nil
    }
}
