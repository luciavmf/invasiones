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
    private let ticksUntilMenuAppears = 20
    /// Pixels the menu moves upward per tick during its entry animation.
    private let menuSlideSpeed = 5

    // MARK: - Menu items
    private enum Item: Int {
        case newGame = 0
        case help    = 1
        case options = 2
        case credits = 3
        case quit    = 4
    }

    private enum Constants {
        static let mainMenuYOffset = 50
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

        let newMenu = Menu(
            image: nil,
            itemCount: 5,
            x: 0,
            y: Video.height - Constants.mainMenuYOffset,
            anchor: Surface.centerHorizontal
        )

        newMenu.addItem(index: Item.newGame.rawValue,  stringId: Res.STR_MENU_NUEVO_JUEGO, flag: Menu.Constants.itemVisible)
        newMenu.addItem(index: Item.help.rawValue,     stringId: Res.STR_MENU_AYUDA,       flag: Menu.Constants.itemVisible)
        newMenu.addItem(index: Item.options.rawValue,  stringId: Res.STR_MENU_OPCIONES,    flag: Menu.Constants.itemVisible)
        newMenu.addItem(index: Item.credits.rawValue,  stringId: Res.STR_MENU_CREDITOS,    flag: Menu.Constants.itemVisible)
        newMenu.addItem(index: Item.quit.rawValue,     stringId: Res.STR_MENU_SALIR,       flag: Menu.Constants.itemVisible)

        if firstBuild {
            firstBuild = false
            menuTargetY = Video.height - newMenu.frame.height - Constants.mainMenuYOffset
            posY = Video.height + newMenu.frame.height + Constants.mainMenuYOffset
            newMenu.setPosition(x: 0, y: Video.height + 15, anchor: Surface.centerHorizontal)
        }

        newMenu.font = ResourceManager.shared.fonts[FontConstants.menuFont]
        menu = newMenu

        Sound.shared.stop(Res.SFX_BATALLA)
        Sound.shared.play(id: Res.SFX_SPLASH, loop: -1)
    }

    override func update() {
        guard let menu = menu else { return }

        count += 1
        if count > ticksUntilMenuAppears {
            if posY > menuTargetY {
                posY -= menuSlideSpeed
            }
            menu.setPosition(x: 0, y: posY, anchor: Surface.centerHorizontal)
        }

        selectedItem = menu.update()

        switch selectedItem {
        case Item.newGame.rawValue:
            stateMachine.setNextState(.game)
        case Item.help.rawValue:
            stateMachine.setNextState(.help)
        case Item.options.rawValue:
            stateMachine.setNextState(.options)
        case Item.credits.rawValue:
            stateMachine.setNextState(.credits)
        case Item.quit.rawValue:
            stateMachine.setNextState(.quit)
        default:
            break
        }
    }

    override func draw(_ video: Video) {
        video.draw(background, 0, 0, 0)
        menu?.draw(video)
    }

    override func exit() {
        menu = nil
    }
}
