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
        confirmMenu?.setPosition(0, 0, Surface.centerVertical | Surface.centerHorizontal)
    }

    override func update() {
        guard let result = confirmMenu?.update() else { return }
        if result == ConfirmationMenu.Selection.right.rawValue {
            stateMachine.setState(.END)
        }
        if result == ConfirmationMenu.Selection.left.rawValue {
            stateMachine.setNextState(.MAIN_MENU)
        }
    }

    override func draw(_ g: Video) {
        g.draw(background, 0, 0, 0)
        confirmMenu?.draw(g)
    }

    override func exit() {
        confirmMenu = nil
    }
}
