//
//  CreditsState.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 08.04.26.
//
//  Credits screen — shows programming and level design credits.
//

import Foundation

class CreditsState: State {

    override func start() {
        background = ResourceManager.shared.getImage(Res.IMG_FONDO)
        button = Button(label: Res.STR_BOTON_MENU, font: nil)
        button?.setPosition(
            x: Video.width  - (button?.width  ?? 0) - Button.Constants.screenEdgeOffset,
            y: Video.height - (button?.height ?? 0) - Button.Constants.screenEdgeOffset,
            anchor: 0)
    }

    override func update() {
        if button?.update() != 0 {
            stateMachine.setNextState(.mainMenu)
        }
    }

    override func draw(_ video: Video) {
        video.draw(background, 0, 0, 0)

        // Title
        video.setFont(ResourceManager.shared.fonts[FontConstants.titleFont], UIColors.text)
        video.write(Res.STR_MENU_CREDITOS, 0, Layout.titleYPosition, Surface.centerHorizontal)

        // Programming
        video.setFont(ResourceManager.shared.fonts[FontConstants.titleFont], UIColors.text)
        video.write(Res.STR_CREDITOS_PROGRAMACION, 0, 260, Surface.centerHorizontal)

        video.setFont(ResourceManager.shared.fonts[FontConstants.buttonFont], UIColors.text)
        video.write(Res.STR_CREDITOS_PROGRAMADOR_1, 0, 310, Surface.centerHorizontal)

        // Level design
        video.setFont(ResourceManager.shared.fonts[FontConstants.titleFont], UIColors.text)
        video.write(Res.STR_CREDITOS_DISENO_DE_NIVEL, 0, 400, Surface.centerHorizontal)

        video.setFont(ResourceManager.shared.fonts[FontConstants.buttonFont], UIColors.text)
        video.write(Res.STR_CREDITOS_DISENADOR_DE_NIVEL_1, 0, 450, Surface.centerHorizontal)

        button?.draw(video)
    }

    override func exit() {}
}
