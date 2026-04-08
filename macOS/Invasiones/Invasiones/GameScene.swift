//
//  GameScene.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  SpriteKit entry point. Equivalent to the GameFrame.Run() loop in C#.
//  Delegates all logic to GameFrame; only handles NSEvent events and the SpriteKit tick.
//

import SpriteKit

class GameScene: SKScene {

    // MARK: - Declarations
    private var gameFrame = GameFrame()
    private var lastKeyPressed: Int = -1

    // MARK: - Scene lifecycle
    override func didMove(to view: SKView) {
        // Fixed size matching the original screen resolution
        size = CGSize(width: ScreenSize.width, height: ScreenSize.height)
        scaleMode = .aspectFit
        // Origin at the bottom-left corner — all Video code assumes (0,0) = bottom-left.
        anchorPoint = CGPoint(x: 0, y: 0)
        backgroundColor = .black

        // The original ran at 20 FPS with SDL_Delay; SpriteKit also accepts mouseMoved.
        view.preferredFramesPerSecond = Program.DEFAULT_FPS
        view.window?.acceptsMouseMovedEvents = true
        // Make the SKView the first responder to receive mouseMoved without a prior click.
        view.window?.makeFirstResponder(view)

        gameFrame.startGame(en: self)
    }

    // MARK: - Loop (SpriteKit calls update(_:) every frame)
    override func update(_ currentTime: TimeInterval) {
        // Sync mouse position from the global cursor position.
        // NSEvent.mouseLocation is always accurate; does not depend on mouseMoved firing.
        if let v = view, let win = v.window {
            let screenPos = NSEvent.mouseLocation
            let winPos = win.convertPoint(fromScreen: screenPos)
            let viewPos = v.convert(winPos, from: nil)
            let scenePos = convertPoint(fromView: viewPos)
            Mouse.shared.X = scenePos.x
            Mouse.shared.Y = CGFloat(ScreenSize.height) - scenePos.y
        }
        gameFrame.update()
        gameFrame.draw()
    }

    // MARK: - Mouse events
    override func mouseDown(with event: NSEvent) {
        let pos = event.location(in: self)
        Mouse.shared.X = pos.x
        Mouse.shared.Y = CGFloat(ScreenSize.height) - pos.y
        Mouse.shared.pressButton(Mouse.Constants.leftButton)
    }

    override func rightMouseDown(with event: NSEvent) {
        let pos = event.location(in: self)
        Mouse.shared.X = pos.x
        Mouse.shared.Y = CGFloat(ScreenSize.height) - pos.y
        Mouse.shared.pressButton(Mouse.Constants.rightButton)
    }

    override func otherMouseDown(with event: NSEvent) {
        Mouse.shared.pressButton(Mouse.Constants.middleButton)
    }

    override func mouseUp(with event: NSEvent) {
        Mouse.shared.releaseButton(Mouse.Constants.leftButton)
    }

    override func rightMouseUp(with event: NSEvent) {
        Mouse.shared.releaseButton(Mouse.Constants.rightButton)
    }

    override func otherMouseUp(with event: NSEvent) {
        Mouse.shared.releaseButton(Mouse.Constants.middleButton)
    }

    override func mouseMoved(with event: NSEvent) {
        let pos = event.location(in: self)
        Mouse.shared.X = pos.x
        Mouse.shared.Y = CGFloat(ScreenSize.height) - pos.y
        view?.window?.acceptsMouseMovedEvents = true
    }

    override func mouseDragged(with event: NSEvent) {
        let pos = event.location(in: self)
        Mouse.shared.X = pos.x
        Mouse.shared.Y = CGFloat(ScreenSize.height) - pos.y
    }

    // MARK: - Keyboard events
    override func keyDown(with event: NSEvent) {
        guard !event.isARepeat else { return }
        let keyCode = Int(event.keyCode)
        if keyCode != lastKeyPressed {
            lastKeyPressed = keyCode
            Keyboard.shared.pressKey(keyCode)
        }
    }

    override func keyUp(with event: NSEvent) {
        lastKeyPressed = -1
        Keyboard.shared.releaseKey(Int(event.keyCode))
    }
}
