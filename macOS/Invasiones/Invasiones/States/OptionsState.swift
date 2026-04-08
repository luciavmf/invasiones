//
//  OptionsState.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Options screen — language selection via radio buttons.
//

import Foundation

class OptionsState: State {

    // MARK: - Layout
    private enum RadioLayout {
        static let startY     = 325   // top of first row
        static let rowHeight  = 36
        static let hoverX     = 460   // hover background left edge
        static let hoverW     = 190   // hover background width
        static let indX       = 472   // radio indicator left edge
        static let indSize    = 12
        static let textX      = 496   // language name text left edge
    }

    // MARK: - State
    private var hoveredLanguage: Language?

    // MARK: - Lifecycle

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

        let mx = Int(Mouse.shared.x)
        let my = Int(Mouse.shared.y)
        hoveredLanguage = nil

        for (i, lang) in Language.allCases.enumerated() {
            let rowY = RadioLayout.startY + i * RadioLayout.rowHeight
            let inRow = mx >= RadioLayout.hoverX
                     && mx <= RadioLayout.hoverX + RadioLayout.hoverW
                     && my >= rowY
                     && my <  rowY + RadioLayout.rowHeight
            if inRow {
                hoveredLanguage = lang
                if Mouse.shared.pressedButtons.contains(Mouse.Constants.leftButton) {
                    Mouse.shared.releaseButton(Mouse.Constants.leftButton)
                    if Language.current != lang {
                        Language.current = lang
                        try? GameText.loadStrings()
                    }
                }
            }
        }
    }

    override func draw(_ video: Video) {
        video.draw(background, 0, 0, 0)

        // Title
        video.setFont(ResourceManager.shared.fonts[FontConstants.titleFont], UIColors.text)
        video.write(Res.STR_MENU_OPCIONES, 0, Layout.titleYPosition, Surface.centerHorizontal)

        // "Language:" label above the list
        video.setFont(ResourceManager.shared.fonts[FontConstants.buttonFont], UIColors.text)
        video.write(Res.STR_LANGUAGE_LABEL, 0, RadioLayout.startY - 28, Surface.centerHorizontal)

        // Radio rows
        for (i, lang) in Language.allCases.enumerated() {
            let rowY  = RadioLayout.startY + i * RadioLayout.rowHeight
            let indY  = rowY + (RadioLayout.rowHeight - RadioLayout.indSize) / 2

            // Hover highlight
            if lang == hoveredLanguage {
                video.setColor(UIColors.menus)
                video.fillRoundedRect(RadioLayout.hoverX, rowY,
                                      RadioLayout.hoverW, RadioLayout.rowHeight - 2,
                                      4, UIColors.alpha)
            }

            // Indicator outline
            video.setColor(UIColors.text)
            video.drawRect(RadioLayout.indX, indY, RadioLayout.indSize, RadioLayout.indSize, 0)

            // Indicator fill when selected
            if lang == Language.current {
                let inset = 3
                video.fillRect(RadioLayout.indX + inset, indY + inset,
                               RadioLayout.indSize - inset * 2, RadioLayout.indSize - inset * 2)
            }

            // Language name (always in the language's own script)
            // Use centerVertical so the text baseline is centred within the row.
            let textY = rowY + RadioLayout.rowHeight / 2 - Video.height / 2
            video.write(lang.displayName, RadioLayout.textX, textY, Surface.centerVertical)
        }

        button?.draw(video)
    }

    override func exit() {}
}
