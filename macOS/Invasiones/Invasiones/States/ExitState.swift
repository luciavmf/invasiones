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

    private var m_confirmMenu: ConfirmationMenu?

    override func start() {
        m_background = ResourceManager.shared.getImage(Res.IMG_SPLASH)
        m_confirmMenu = ConfirmationMenu(Res.STR_CONFIRMACION_SALIR, Res.STR_NO, Res.STR_SI)
        m_confirmMenu?.setPosition(0, 0, Surface.centerVertical | Surface.centerHorizontal)
    }

    override func update() {
        guard let result = m_confirmMenu?.update() else { return }
        if result == ConfirmationMenu.SELECCION.DERECHO.rawValue {
            stateMachine.setState(.END)
        }
        if result == ConfirmationMenu.SELECCION.IZQUIERDO.rawValue {
            stateMachine.setNextState(.MAIN_MENU)
        }
    }

    override func draw(_ g: Video) {
        g.draw(m_background, 0, 0, 0)
        m_confirmMenu?.draw(g)
    }

    override func exit() {
        m_confirmMenu = nil
    }
}
