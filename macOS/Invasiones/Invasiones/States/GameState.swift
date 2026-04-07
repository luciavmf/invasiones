//
//  GameState.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of EstadoJuego.cs — active game state containing the Episode.
//

import Foundation

/// The game state where the battle takes place.
/// Contains and drives an Episode, handles the pause menu and the exit-confirmation dialog.
class GameState: State {

    // MARK: - Enums
    private enum State { case start, won, lost, menu, playing, confirmacion }
    private enum MenuItem: Int { case continuar = 0, quit = 1 }

    // MARK: - Declarations
    private var episode: Episode?
    private var gameMenu: Menu?
    private var confirmMenu: ConfirmationMenu?
    private var stateValue: State = .start

    // MARK: - State overrides

    override func start() {
        stateValue = .start

        gameMenu = Menu(image: nil, itemCount: 2, x: 0, y: 0,
                              anchor: Surface.centerHorizontal | Surface.centerVertical)
        gameMenu?.font = ResourceManager.shared.fonts[Definitions.FONT_MENU]
        gameMenu?.addItem(index: MenuItem.continuar.rawValue,
                          stringId: Res.STR_MENU_CONTINUAR, flag: Menu.ITEM_VISIBLE)
        gameMenu?.addItem(index: MenuItem.quit.rawValue,
                          stringId: Res.STR_MENU_SALIR, flag: Menu.ITEM_VISIBLE)
    }

    override func update() {
        switch stateValue {

        case .start:
            episode = Episode()
            episode?.start()
            stateValue = .playing

            button = Button(label: Res.STR_BOTON_MENU_DEL_JUEGO, font: nil)
            if let b = button {
                b.setPosition(x: Video.width - b.width - Button.OFFSET_LIMITE_PANTALLA,
                              y: Button.OFFSET_LIMITE_PANTALLA, anchor: 0)
            }

            confirmMenu = ConfirmationMenu(Res.STR_CONFIRMACION_SALIR,
                                                      Res.STR_NO, Res.STR_SI)
            confirmMenu?.setPosition(x: 0, y: 0, anchor: Surface.centerVertical | Surface.centerHorizontal)

        case .playing:
            episode?.update()
            if episode?.state == .playing {
                if button?.update() != 0 {
                    setState(.menu)
                }
            }
            if episode?.state == .end {
                stateMachine.setNextState(.mainMenu)
            }

        case .menu:
            if let item = gameMenu?.update() {
                switch MenuItem(rawValue: item) {
                case .continuar: setState(.playing)
                case .quit: setState(.confirmacion)
                case .none: break
                }
            }

        case .confirmacion:
            if let result = confirmMenu?.update() {
                if result == ConfirmationMenu.Selection.left.rawValue {
                    setState(.playing)
                }
                if result == ConfirmationMenu.Selection.right.rawValue {
                    stateMachine.setNextState(.mainMenu)
                }
            }

        case .won, .lost:
            break
        }
    }

    override func draw(_ g: Video) {
        switch stateValue {

        case .playing:
            episode?.draw(g)
            if episode?.state == .playing {
                button?.draw(g)
            }

        case .menu:
            episode?.draw(g)
            gameMenu?.draw(g)
            g.setFont(ResourceManager.shared.fonts[Definitions.FONT_TITLE],
                           Definitions.COLOR_WHITE)
            g.write(Res.STR_JUEGO_PAUSADO, 0, Definitions.GAME_PAUSED_Y,
                       Surface.centerVertical | Surface.centerHorizontal)

        case .confirmacion:
            episode?.draw(g)
            confirmMenu?.draw(g)

        default:
            break
        }
    }

    override func exit() {}

    // MARK: - Private

    private func setState(_ state: State) {
        stateValue = state
    }
}

