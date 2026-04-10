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
    private enum State { case start, won, lost, menu, playing, confirmation }
    private enum MenuItem: Int { case continuar = 0, quit = 1 }

    private let gamePausedY = -200

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
        gameMenu?.font = ResourceManager.shared.fonts[FontConstants.menuFont]
        gameMenu?.addItem(index: MenuItem.continuar.rawValue,
                          stringId: Res.STR_MENU_CONTINUAR, flag: Menu.Constants.itemVisible)
        gameMenu?.addItem(index: MenuItem.quit.rawValue,
                          stringId: Res.STR_MENU_SALIR, flag: Menu.Constants.itemVisible)
    }

    override func update() {
        switch stateValue {

        case .start:
            episode = Episode()
            episode?.start()
            stateValue = .playing

            button = Button(label: Res.STR_BOTON_MENU_DEL_JUEGO, font: nil)
            button?.setPosition(x: Video.width - Button.Constants.defaultWidth - Button.Constants.screenEdgeOffset,
                                y: Button.Constants.screenEdgeOffset, anchor: 0)

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
                case .quit: setState(.confirmation)
                case .none: break
                }
            }

        case .confirmation:
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

    override func draw(_ video: Video) {
        switch stateValue {

        case .playing:
            episode?.draw(video)
            if episode?.state == .playing {
                button?.draw(video)
            }

        case .menu:
            episode?.draw(video)
            gameMenu?.draw(video)
            video.setFont(ResourceManager.shared.fonts[FontConstants.titleFont],
                           GameColor.white)
            video.write(Res.STR_JUEGO_PAUSADO, 0, gamePausedY,
                       Surface.centerVertical | Surface.centerHorizontal)

        case .confirmation:
            episode?.draw(video)
            confirmMenu?.draw(video)

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

