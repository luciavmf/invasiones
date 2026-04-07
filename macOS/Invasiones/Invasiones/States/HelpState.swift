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
    private enum Substate: Int {
        case select = 0, move, attack, objective, scroll, hud, heal, tips, win
        static let total = 9
    }

    // MARK: - Declarations
    private var substate: Substate = .select
    private var backButton: Button?
    private var nextButton: Button?
    private var currentScreenshot: Animation?

    // MARK: - Methods

    override func start() {
        background = ResourceManager.shared.getImage(Res.IMG_FONDO)

        let fnt = ResourceManager.shared.fonts[FontIndex.sans18.rawValue]

        button = Button(label: Res.STR_BOTON_MENU, font: fnt)
        button?.setPosition(
            x: Video.width - (button?.width ?? 0) - Button.OFFSET_LIMITE_PANTALLA,
            y: Video.height - (button?.height ?? 0) - Button.OFFSET_LIMITE_PANTALLA,
            anchor: 0
        )

        nextButton = Button(label: Res.STR_SIGUIENTE, font: fnt)
        nextButton?.setPosition(
            x: Video.width - (nextButton?.width ?? 0) - Button.OFFSET_LIMITE_PANTALLA,
            y: Video.height - (nextButton?.height ?? 0) - Button.OFFSET_LIMITE_PANTALLA,
            anchor: 0
        )

        backButton = Button(label: Res.STR_ATRAS, font: fnt)
        backButton?.setPosition(
            x: Video.width - (nextButton?.width ?? 0) * 2 - Button.OFFSET_LIMITE_PANTALLA,
            y: Video.height - (nextButton?.height ?? 0) - Button.OFFSET_LIMITE_PANTALLA,
            anchor: 0
        )

        substate = .select
        loadScreenshot(substate)
    }

    override func update() {
        if button?.update() != 0 {
            let next = substate.rawValue + 1
            if next > Substate.win.rawValue {
                stateMachine.setNextState(.mainMenu)
            } else if let next = Substate(rawValue: next) {
                substate = next
                loadScreenshot(next)
            }
        }

        if backButton?.update() != 0, substate != .select {
            let prev = substate.rawValue - 1
            if let prev = Substate(rawValue: prev) {
                substate = prev
                loadScreenshot(prev)
            }
        }

        currentScreenshot?.update()
    }

    override func draw(_ g: Video) {
        g.draw(background, 0, 0, 0)

        g.setFont(ResourceManager.shared.fonts[Definitions.FONT_TITLE],
                       Definitions.COLOR_TITLE)
        g.write(Res.STR_MENU_AYUDA, 0, Definitions.TITLE_Y, Surface.centerHorizontal)

        if substate.rawValue < Substate.total {
            g.setFont(ResourceManager.shared.fonts[Definitions.FONT_HELP_TITLE],
                           Definitions.GUI_COLOR_TEXT)
            g.write(Res.STR_MENU_AYUDA_TEXTO_SELECCIONAR_01 + substate.rawValue * 2,
                       0, Definitions.HELP_ITEM_Y, Surface.centerHorizontal)

            g.setFont(ResourceManager.shared.fonts[Definitions.FONT_HELP],
                           Definitions.GUI_COLOR_TEXT)
            g.write(Res.STR_MENU_AYUDA_TEXTO_SELECCIONAR_02 + substate.rawValue * 2,
                       0, Definitions.HELP_TEXT_Y, Surface.centerHorizontal)
        }

        currentScreenshot?.draw(g: g, x: 0, y: 150, anchor: Surface.centerHorizontal | Surface.centerVertical)

        if substate != .select { backButton?.draw(g) }
        if substate != .win {
            nextButton?.draw(g)
        } else {
            button?.draw(g)
        }
    }

    override func exit() {}

    // MARK: - Private

    private func loadScreenshot(_ sub: Substate) {
        let animIdx = Res.ANIM_AYUDA_SELECCION + sub.rawValue
        let anims = ResourceManager.shared.animations
        guard animIdx < anims.count, let anim = anims[animIdx] else {
            currentScreenshot = nil
            return
        }
        try? anim.load()
        anim.play()
        anim.loop = true
        currentScreenshot = anim
    }
}
