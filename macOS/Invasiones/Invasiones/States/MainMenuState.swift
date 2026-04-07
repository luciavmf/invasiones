//
//  MainMenuState.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of EstadoMenuPpal.cs — main menu with entry animation.
//

import Foundation

/// Displays the main menu and directs the player to the option they select.
/// The menu slides up from the bottom of the screen on first entry.
class MainMenuState: State {

    // MARK: - Constants
    /// Number of ticks to wait before the menu starts sliding into view.
    private let CUENTA_HASTA_MOSTRAR_MENU = 20
    /// Pixels the menu moves upward per tick during its entry animation.
    private let INCREMENTO_MENU_Y = 5

    // MARK: - Menu items
    private enum Item: Int {
        case newGame = 0
        case help = 1
        case quit = 2
    }

    // MARK: - Declarations
    private var selectedItem: Int = -1
    private var menu: Menu?
    /// The final Y position the menu should reach after animating in.
    private var menuTargetY: Int = 0
    /// The current Y position of the menu during animation.
    private var posY: Int = 0
    /// `true` on the first entry so the slide-in animation only initialises once.
    private var firstBuild: Bool = true

    // MARK: - Initializer
    override init(_ sm: StateMachine) {
        super.init(sm)
        firstBuild = true
    }

    // MARK: - Methods

    override func start() {
        background = ResourceManager.shared.getImage(Res.IMG_SPLASH)

        Mouse.shared.setCursor(ResourceManager.shared.getImage(Res.IMG_CURSOR))
        Mouse.shared.showCursor()

        let newMenu = Menu(image: nil,
                        itemCount: 3,
                        x: 0,
                        y: Video.height - Definitions.MAIN_MENU_Y_OFFSET,
                        anchor: Surface.centerHorizontal)

        newMenu.addItem(index: Item.newGame.rawValue, stringId: Res.STR_MENU_NUEVO_JUEGO, flag: Menu.ITEM_VISIBLE)
        newMenu.addItem(index: Item.help.rawValue, stringId: Res.STR_MENU_AYUDA, flag: Menu.ITEM_VISIBLE)
        newMenu.addItem(index: Item.quit.rawValue, stringId: Res.STR_MENU_SALIR, flag: Menu.ITEM_VISIBLE)

        if firstBuild {
            firstBuild = false
            menuTargetY = Video.height - newMenu.height - Definitions.MAIN_MENU_Y_OFFSET
            posY              = Video.height + newMenu.height + Definitions.MAIN_MENU_Y_OFFSET
            newMenu.setPosition(x: 0, y: Video.height + 15, anchor: Surface.centerHorizontal)
        }

        newMenu.font = ResourceManager.shared.fonts[Definitions.FONT_MENU]
        menu = newMenu

        Sound.shared.stop(Res.SFX_BATALLA)
        Sound.shared.play(id: Res.SFX_SPLASH, loop: -1)
    }

    override func update() {
        guard let menu = menu else { return }

        count += 1
        if count > CUENTA_HASTA_MOSTRAR_MENU {
            if posY > menuTargetY {
                posY -= INCREMENTO_MENU_Y
            }
            menu.setPosition(x: 0, y: posY, anchor: Surface.centerHorizontal)
        }

        selectedItem = menu.update()

        switch selectedItem {
        case Item.newGame.rawValue:
            stateMachine.setNextState(.game)
        case Item.help.rawValue:
            stateMachine.setNextState(.help)
        case Item.quit.rawValue:
            stateMachine.setNextState(.quit)
        default:
            break
        }
    }

    override func draw(_ g: Video) {
        g.draw(background, 0, 0, 0)
        menu?.draw(g)
    }

    override func exit() {
        menu = nil
    }
}
