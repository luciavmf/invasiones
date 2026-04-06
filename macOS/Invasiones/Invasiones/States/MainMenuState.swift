//
//  MainMenuState.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of EstadoMenuPpal.cs — main menu with entry animation.
//

import Foundation

class MainMenuState: State {

    // MARK: - Constants
    private let CUENTA_HASTA_MOSTRAR_MENU = 20
    private let INCREMENTO_MENU_Y         = 5

    // MARK: - Menu items
    private enum ITEM: Int {
        case NEW_GAME = 0
        case HELP       = 1
        case QUIT       = 2
    }

    // MARK: - Declarations
    private var m_selectedItem:      Int = -1
    private var m_menu:                  Menu?
    private var m_menuTargetY:  Int = 0
    private var m_posY:             Int = 0
    private var m_firstBuild:  Bool = true

    // MARK: - Initializer
    override init(_ sm: StateMachine) {
        super.init(sm)
        m_firstBuild = true
    }

    // MARK: - Methods

    override func start() {
        m_background = ResourceManager.shared.getImage(Res.IMG_SPLASH)

        Mouse.shared.setCursor(ResourceManager.shared.getImage(Res.IMG_CURSOR))
        Mouse.shared.showCursor()

        let menu = Menu(image: nil,
                        itemCount: 3,
                        x: 0,
                        y: Video.height - Definitions.MAIN_MENU_Y_OFFSET,
                        anchor: Surface.centerHorizontal)

        menu.addItem(ITEM.NEW_GAME.rawValue, Res.STR_MENU_NUEVO_JUEGO, Menu.ITEM_VISIBLE)
        menu.addItem(ITEM.HELP.rawValue,       Res.STR_MENU_AYUDA,       Menu.ITEM_VISIBLE)
        menu.addItem(ITEM.QUIT.rawValue,       Res.STR_MENU_SALIR,       Menu.ITEM_VISIBLE)

        if m_firstBuild {
            m_firstBuild   = false
            m_menuTargetY   = Video.height - menu.height - Definitions.MAIN_MENU_Y_OFFSET
            m_posY              = Video.height + menu.height + Definitions.MAIN_MENU_Y_OFFSET
            menu.setPosition(0, Video.height + 15, Surface.centerHorizontal)
        }

        menu.setFont(ResourceManager.shared.fonts[Definitions.FONT_MENU])
        m_menu = menu

        Sound.shared.stop(Res.SFX_BATALLA)
        Sound.shared.play(Res.SFX_SPLASH, -1)
    }

    override func update() {
        guard let menu = m_menu else { return }

        m_count += 1
        if m_count > CUENTA_HASTA_MOSTRAR_MENU {
            if m_posY > m_menuTargetY {
                m_posY -= INCREMENTO_MENU_Y
            }
            menu.setPosition(0, m_posY, Surface.centerHorizontal)
        }

        m_selectedItem = menu.update()

        switch m_selectedItem {
        case ITEM.NEW_GAME.rawValue:
            stateMachine.setNextState(.GAME)
        case ITEM.HELP.rawValue:
            stateMachine.setNextState(.HELP)
        case ITEM.QUIT.rawValue:
            stateMachine.setNextState(.QUIT)
        default:
            break
        }
    }

    override func draw(_ g: Video) {
        g.draw(m_background, 0, 0, 0)
        m_menu?.draw(g)
    }

    override func exit() {
        m_menu = nil
    }
}
