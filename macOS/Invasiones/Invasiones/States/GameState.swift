//
//  GameState.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of EstadoJuego.cs — active game state containing the Episode.
//

import Foundation

class GameState: State {

    // MARK: - Enums
    private enum STATE { case START, WON, LOST, MENU, PLAYING, CONFIRMACION }
    private enum MENU_ITEM: Int { case CONTINUAR = 0, QUIT = 1 }

    // MARK: - Declarations
    private var m_episode:            Episode?
    private var m_gameMenu:       Menu?
    private var m_confirmMenu: ConfirmationMenu?
    private var m_state:             STATE = .START

    // MARK: - State overrides

    override func start() {
        m_state = .START

        m_gameMenu = Menu(image: nil, itemCount: 2, x: 0, y: 0,
                              anchor: Surface.centerHorizontal | Surface.centerVertical)
        m_gameMenu?.setFont(
            ResourceManager.shared.fonts[Definitions.FONT_MENU])
        m_gameMenu?.addItem(MENU_ITEM.CONTINUAR.rawValue,
                                    Res.STR_MENU_CONTINUAR, Menu.ITEM_VISIBLE)
        m_gameMenu?.addItem(MENU_ITEM.QUIT.rawValue,
                                    Res.STR_MENU_SALIR, Menu.ITEM_VISIBLE)
    }

    override func update() {
        switch m_state {

        case .START:
            m_episode = Episode()
            m_episode?.start()
            m_state = .PLAYING

            m_button = Button(label: Res.STR_BOTON_MENU_DEL_JUEGO, font: nil)
            if let b = m_button {
                b.setPosition(Video.width - b.width - Button.OFFSET_LIMITE_PANTALLA,
                                 Button.OFFSET_LIMITE_PANTALLA, 0)
            }

            m_confirmMenu = ConfirmationMenu(Res.STR_CONFIRMACION_SALIR,
                                                      Res.STR_NO, Res.STR_SI)
            m_confirmMenu?.setPosition(0, 0, Surface.centerVertical | Surface.centerHorizontal)

        case .PLAYING:
            m_episode?.update()
            if m_episode?.state == .PLAYING {
                if m_button?.update() != 0 {
                    setState(.MENU)
                }
            }
            if m_episode?.state == .END {
                stateMachine.setNextState(.MAIN_MENU)
            }

        case .MENU:
            if let item = m_gameMenu?.update() {
                switch MENU_ITEM(rawValue: item) {
                case .CONTINUAR: setState(.PLAYING)
                case .QUIT:     setState(.CONFIRMACION)
                case .none:      break
                }
            }

        case .CONFIRMACION:
            if let result = m_confirmMenu?.update() {
                if result == ConfirmationMenu.SELECCION.IZQUIERDO.rawValue {
                    setState(.PLAYING)
                }
                if result == ConfirmationMenu.SELECCION.DERECHO.rawValue {
                    stateMachine.setNextState(.MAIN_MENU)
                }
            }

        case .WON, .LOST:
            break
        }
    }

    override func draw(_ g: Video) {
        switch m_state {

        case .PLAYING:
            m_episode?.draw(g)
            if m_episode?.state == .PLAYING {
                m_button?.draw(g)
            }

        case .MENU:
            m_episode?.draw(g)
            m_gameMenu?.draw(g)
            g.setFont(ResourceManager.shared.fonts[Definitions.FONT_TITLE],
                           Definitions.COLOR_WHITE)
            g.write(Res.STR_JUEGO_PAUSADO, 0, Definitions.GAME_PAUSED_Y,
                       Surface.centerVertical | Surface.centerHorizontal)

        case .CONFIRMACION:
            m_episode?.draw(g)
            m_confirmMenu?.draw(g)

        default:
            break
        }
    }

    override func exit() {}

    // MARK: - Private

    private func setState(_ state: STATE) {
        m_state = state
    }
}

