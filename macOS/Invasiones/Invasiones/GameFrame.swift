//
//  GameFrame.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of GameFrame.cs — main game coordinator.
//  The original had a blocking loop with SDL_Delay; here the loop is provided by
//  SpriteKit via GameScene.update(). GameFrame only contains state logic.
//

import SpriteKit

class GameFrame {

    // MARK: - State enum (equivalent to GameFrame.STATE in C#)
    enum STATE {
        case INVALID
        case END
        case LOGO
        case GAME
        case HELP
        case MAIN_MENU
        case INTRO_CONSEQUENCES
        case CREDITS
        case OPTIONS
        case QUIT
    }

    // MARK: - Declarations
    private(set) var stateMachine: StateMachine!
    private var video: Video?

    static var FPS: Double = 0
    static var UPS: Double = 0

    // MARK: - Initializer
    init() {}

    // MARK: - Game start
    /// Called once from GameScene.didMove(to:).
    func startGame(en escena: SKScene) {
        video = Video(escena: escena)

        Mouse.shared.positionCursor(
            CGFloat(Program.SCREEN_WIDTH) / 2,
            CGFloat(Program.SCREEN_HEIGHT) / 2
        )
        Mouse.shared.hideCursor()

        GameText.loadStrings()
        ResourceManager.shared.loadResourcePaths()
        ResourceManager.shared.readSpriteInfo()
        ResourceManager.shared.readAnimationInfo()
        ResourceManager.shared.loadFonts()

        Sound.shared.loadAllSounds()

        stateMachine = StateMachine()
        stateMachine.addState(.LOGO,           LogoState(stateMachine))
        stateMachine.addState(.MAIN_MENU, MainMenuState(stateMachine))
        stateMachine.addState(.GAME,          GameState(stateMachine))
        stateMachine.addState(.END,            nil)
        stateMachine.addState(.HELP,          HelpState(stateMachine))
        stateMachine.addState(.OPTIONS,       OptionsState(stateMachine))
        stateMachine.addState(.QUIT,          ExitState(stateMachine))

        stateMachine.setState(.LOGO)
        stateMachine.update() // triggers start() on the first state
    }

    // MARK: - Loop (called by GameScene.update every frame)
    func update() {
        guard stateMachine.currentState != .END else {
            quitApp()
            return
        }
        Mouse.shared.update()
        stateMachine.update()
    }

    func draw() {
        guard let v = video else { return }
        v.clear()
        stateMachine.draw(v)
        Mouse.shared.drawCursor(en: v)
    }

    // MARK: - Exit
    private func quitApp() {
        releaseAllResources()
        NSApplication.shared.terminate(nil)
    }

    private func releaseAllResources() {
        stateMachine?.dispose()
        stateMachine = nil
        Log.shared.dispose()
    }
}
