//
//  OptionsState.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of EstadoOpcionea.cs — options screen (currently only shows title and returns).
//

import Foundation

class OptionsState: State {

    override func start() {
        m_background = ResourceManager.shared.getImage(Res.IMG_FONDO)
        m_button = Button(label: Res.STR_BOTON_MENU, font: nil)
        m_button?.setPosition(
            Video.width - (m_button?.width ?? 0) - Button.OFFSET_LIMITE_PANTALLA,
            Video.height  - (m_button?.height  ?? 0) - Button.OFFSET_LIMITE_PANTALLA, 0)
    }

    override func update() {
        if m_button?.update() != 0 {
            stateMachine.setNextState(.MAIN_MENU)
        }
    }

    override func draw(_ g: Video) {
        g.draw(m_background, 0, 0, 0)
        g.setFont(ResourceManager.shared.fonts[Definitions.FONT_TITLE],
                       Definitions.GUI_COLOR_TEXT)
        g.write(Res.STR_MENU_OPCIONES, 0, Definitions.TITLE_Y, Surface.centerHorizontal)
        m_button?.draw(g)
    }

    override func exit() {}
}
