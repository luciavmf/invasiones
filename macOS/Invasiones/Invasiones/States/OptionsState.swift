//
//  OptionsState.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Options screen — language selection and sound toggle via radio buttons.
//

import Foundation

class OptionsState: State {

    // MARK: - Layout
    private enum SoundLayout {
        static let labelY   = 200
        static let startY   = 228
        static let rowHeight = 36
        static let hoverX   = 460
        static let hoverW   = 190
        static let indX     = 472
        static let indSize  = 12
        static let textX    = 496
    }

    private enum RadioLayout {
        static let startY    = 325
        static let rowHeight = 36
        static let hoverX    = 460
        static let hoverW    = 190
        static let indX      = 472
        static let indSize   = 12
        static let textX     = 496
    }

    // MARK: - State
    private var hoveredLanguage: Language?
    private var soundRowHovered = false

    // MARK: - Lifecycle

    override func start() {
        background = ResourceManager.shared.getImage(Res.IMG_FONDO)
        button = Button(label: Res.STR_BOTON_MENU, font: nil)
        let bw = button?.frame.width  ?? 0
        let bh = button?.frame.height ?? 0
        button?.setPosition(
            x: Video.width  - bw - Button.Constants.screenEdgeOffset,
            y: Video.height - bh - Button.Constants.screenEdgeOffset,
            anchor: 0)
    }

    override func update() {
        if button?.update() != 0 {
            stateMachine.setNextState(.mainMenu)
        }

        let mx = Int(Mouse.shared.x)
        let my = Int(Mouse.shared.y)

        // Sound toggle
        soundRowHovered = mx >= SoundLayout.hoverX
                       && mx <= SoundLayout.hoverX + SoundLayout.hoverW
                       && my >= SoundLayout.startY
                       && my <  SoundLayout.startY + SoundLayout.rowHeight
        if soundRowHovered && Mouse.shared.pressedButtons.contains(Mouse.Constants.leftButton) {
            Mouse.shared.releaseButton(Mouse.Constants.leftButton)
            Sound.shared.setMuted(!Sound.shared.isMuted)
        }

        // Language selection
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
        video.setFont(ResourceManager.shared.fonts[FontConstants.titleFont], Theme.text)
        video.write(Res.STR_MENU_OPCIONES, 0, Layout.titleYPosition, Surface.centerHorizontal)

        // Sound section
        video.setFont(ResourceManager.shared.fonts[FontConstants.buttonFont], Theme.text)
        video.write(Res.STR_SOUND_LABEL, 0, SoundLayout.labelY, Surface.centerHorizontal)

        let indSoundY = SoundLayout.startY + (SoundLayout.rowHeight - SoundLayout.indSize) / 2
        if soundRowHovered {
            video.setColor(Theme.menus)
            video.fillRoundedRect(SoundLayout.hoverX, SoundLayout.startY,
                                  SoundLayout.hoverW, SoundLayout.rowHeight - 2,
                                  4, Theme.alpha)
        }
        video.setColor(Theme.text)
        video.drawRect(SoundLayout.indX, indSoundY, SoundLayout.indSize, SoundLayout.indSize, 0)
        if !Sound.shared.isMuted {
            let inset = 3
            video.fillRect(SoundLayout.indX + inset, indSoundY + inset,
                           SoundLayout.indSize - inset * 2, SoundLayout.indSize - inset * 2)
        }
        let soundTextY = SoundLayout.startY + SoundLayout.rowHeight / 2 - Video.height / 2
        let soundLabel = Sound.shared.isMuted ? "Off" : "On"
        video.write(soundLabel, SoundLayout.textX, soundTextY, Surface.centerVertical)

        // Language section
        video.setFont(ResourceManager.shared.fonts[FontConstants.buttonFont], Theme.text)
        video.write(Res.STR_LANGUAGE_LABEL, 0, RadioLayout.startY - 28, Surface.centerHorizontal)

        for (i, lang) in Language.allCases.enumerated() {
            let rowY = RadioLayout.startY + i * RadioLayout.rowHeight
            let indY = rowY + (RadioLayout.rowHeight - RadioLayout.indSize) / 2

            if lang == hoveredLanguage {
                video.setColor(Theme.menus)
                video.fillRoundedRect(RadioLayout.hoverX, rowY,
                                      RadioLayout.hoverW, RadioLayout.rowHeight - 2,
                                      4, Theme.alpha)
            }

            video.setColor(Theme.text)
            video.drawRect(RadioLayout.indX, indY, RadioLayout.indSize, RadioLayout.indSize, 0)

            if lang == Language.current {
                let inset = 3
                video.fillRect(RadioLayout.indX + inset, indY + inset,
                               RadioLayout.indSize - inset * 2, RadioLayout.indSize - inset * 2)
            }

            let textY = rowY + RadioLayout.rowHeight / 2 - Video.height / 2
            video.write(lang.displayName, RadioLayout.textX, textY, Surface.centerVertical)
        }

        button?.draw(video)
    }

    override func exit() {}
}
