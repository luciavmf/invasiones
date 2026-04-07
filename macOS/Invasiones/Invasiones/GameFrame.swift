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

/// Main game coordinator. Provides the game loop and hosts the state machine.
/// The original C# version contained a blocking loop with SDL_Delay; here the loop
/// is driven by SpriteKit via GameScene.update(), and GameFrame only handles state logic.
class GameFrame {

    // MARK: - State enum (equivalent to GameFrame.STATE in C#)
    /// All top-level game screens.
    enum State {
        case invalid
        case end
        case logo
        case game
        case help
        case mainMenu
        case introConsequences
        case credits
        case options
        case quit
    }

    // MARK: - Declarations
    private(set) var stateMachine: StateMachine!
    private var video: Video?

    /// The current frames per second (updated each interval).
    static var FPS: Double = 0
    /// The current updates per second (updated each interval).
    static var UPS: Double = 0

    // MARK: - Initializer
    init() {}

    // MARK: - Game start
    /// Initialises the state machine and all game states. Called once from GameScene.didMove(to:).
    func startGame(en escena: SKScene) {
        video = Video(escena: escena)

        Mouse.shared.positionCursor(
            x: CGFloat(ScreenSize.SCREEN_WIDTH) / 2,
            y: CGFloat(ScreenSize.SCREEN_HEIGHT) / 2
        )
        Mouse.shared.hideCursor()

        do {
            try GameText.loadStrings()
            try ResourceManager.shared.loadResourcePaths()
            try ResourceManager.shared.readSpriteInfo()
            try ResourceManager.shared.readAnimationInfo()
            try ResourceManager.shared.loadFonts()
        } catch {
            Log.shared.error(error.localizedDescription)
        }

        Sound.shared.loadAllSounds()

        stateMachine = StateMachine()
        stateMachine.addState(key: .logo, state: LogoState(stateMachine))
        stateMachine.addState(key: .mainMenu, state: MainMenuState(stateMachine))
        stateMachine.addState(key: .game, state: GameState(stateMachine))
        stateMachine.addState(key: .end, state: nil)
        stateMachine.addState(key: .help, state: HelpState(stateMachine))
        stateMachine.addState(key: .options, state: OptionsState(stateMachine))
        stateMachine.addState(key: .quit, state: ExitState(stateMachine))

        stateMachine.setState(.logo)
        stateMachine.update() // triggers start() on the first state
    }

    // MARK: - Loop (called by GameScene.update every frame)
    /// Advances mouse state and ticks the state machine. Exits the app if the END state is reached.
    func update() {
        guard stateMachine.currentState != .end else {
            quitApp()
            return
        }
        Mouse.shared.update()
        stateMachine.update()
    }

    /// Clears the canvas and renders the current state followed by the mouse cursor.
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
