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
        background = ResourceManager.shared.getImage(Res.IMG_FONDO)
        button = Button(label: Res.STR_BOTON_MENU, font: nil)
        button?.setPosition(
            x: Video.width - (button?.width ?? 0) - Button.OFFSET_LIMITE_PANTALLA,
            y: Video.height - (button?.height ?? 0) - Button.OFFSET_LIMITE_PANTALLA,
            anchor: 0)
    }

    override func update() {
        if button?.update() != 0 {
            stateMachine.setNextState(.MAIN_MENU)
        }
    }

    override func draw(_ g: Video) {
        g.draw(background, 0, 0, 0)
        g.setFont(ResourceManager.shared.fonts[Definitions.FONT_TITLE],
                       Definitions.GUI_COLOR_TEXT)
        g.write(Res.STR_MENU_OPCIONES, 0, Definitions.TITLE_Y, Surface.centerHorizontal)
        button?.draw(g)
    }

    override func exit() {}
}
