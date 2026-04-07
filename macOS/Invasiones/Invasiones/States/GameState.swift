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
    private enum STATE { case START, WON, LOST, MENU, PLAYING, CONFIRMACION }
    private enum MENU_ITEM: Int { case CONTINUAR = 0, QUIT = 1 }

    // MARK: - Declarations
    private var episode: Episode?
    private var gameMenu: Menu?
    private var confirmMenu: ConfirmationMenu?
    private var stateValue: STATE = .START

    // MARK: - State overrides

    override func start() {
        stateValue = .START

        gameMenu = Menu(image: nil, itemCount: 2, x: 0, y: 0,
                              anchor: Surface.centerHorizontal | Surface.centerVertical)
        gameMenu?.font = ResourceManager.shared.fonts[Definitions.FONT_MENU]
        gameMenu?.addItem(index: MENU_ITEM.CONTINUAR.rawValue,
                          stringId: Res.STR_MENU_CONTINUAR, flag: Menu.ITEM_VISIBLE)
        gameMenu?.addItem(index: MENU_ITEM.QUIT.rawValue,
                          stringId: Res.STR_MENU_SALIR, flag: Menu.ITEM_VISIBLE)
    }

    override func update() {
        switch stateValue {

        case .START:
            episode = Episode()
            episode?.start()
            stateValue = .PLAYING

            button = Button(label: Res.STR_BOTON_MENU_DEL_JUEGO, font: nil)
            if let b = button {
                b.setPosition(x: Video.width - b.width - Button.OFFSET_LIMITE_PANTALLA,
                              y: Button.OFFSET_LIMITE_PANTALLA, anchor: 0)
            }

            confirmMenu = ConfirmationMenu(Res.STR_CONFIRMACION_SALIR,
                                                      Res.STR_NO, Res.STR_SI)
            confirmMenu?.setPosition(x: 0, y: 0, anchor: Surface.centerVertical | Surface.centerHorizontal)

        case .PLAYING:
            episode?.update()
            if episode?.state == .PLAYING {
                if button?.update() != 0 {
                    setState(.MENU)
                }
            }
            if episode?.state == .END {
                stateMachine.setNextState(.MAIN_MENU)
            }

        case .MENU:
            if let item = gameMenu?.update() {
                switch MENU_ITEM(rawValue: item) {
                case .CONTINUAR: setState(.PLAYING)
                case .QUIT:     setState(.CONFIRMACION)
                case .none:      break
                }
            }

        case .CONFIRMACION:
            if let result = confirmMenu?.update() {
                if result == ConfirmationMenu.Selection.left.rawValue {
                    setState(.PLAYING)
                }
                if result == ConfirmationMenu.Selection.right.rawValue {
                    stateMachine.setNextState(.MAIN_MENU)
                }
            }

        case .WON, .LOST:
            break
        }
    }

    override func draw(_ g: Video) {
        switch stateValue {

        case .PLAYING:
            episode?.draw(g)
            if episode?.state == .PLAYING {
                button?.draw(g)
            }

        case .MENU:
            episode?.draw(g)
            gameMenu?.draw(g)
            g.setFont(ResourceManager.shared.fonts[Definitions.FONT_TITLE],
                           Definitions.COLOR_WHITE)
            g.write(Res.STR_JUEGO_PAUSADO, 0, Definitions.GAME_PAUSED_Y,
                       Surface.centerVertical | Surface.centerHorizontal)

        case .CONFIRMACION:
            episode?.draw(g)
            confirmMenu?.draw(g)

        default:
            break
        }
    }

    override func exit() {}

    // MARK: - Private

    private func setState(_ state: STATE) {
        stateValue = state
    }
}

