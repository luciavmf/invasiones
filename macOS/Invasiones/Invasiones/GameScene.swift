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
    private var ultimaTeclaApretada: Int = -1

    // MARK: - Scene lifecycle
    override func didMove(to view: SKView) {
        // Fixed size matching the original screen resolution
        size = CGSize(width: Programa.ANCHO_DE_LA_PANTALLA, height: Programa.ALTO_DE_LA_PANTALLA)
        scaleMode = .aspectFit
        // Origin at the bottom-left corner — all Video code assumes (0,0) = bottom-left.
        anchorPoint = CGPoint(x: 0, y: 0)
        backgroundColor = .black

        // The original ran at 20 FPS with SDL_Delay; SpriteKit also accepts mouseMoved.
        view.preferredFramesPerSecond = Programa.FPS_POR_DEFECTO
        view.window?.acceptsMouseMovedEvents = true
        // Make the SKView the first responder to receive mouseMoved without a prior click.
        view.window?.makeFirstResponder(view)

        gameFrame.iniciarJuego(en: self)
    }

    // MARK: - Loop (SpriteKit calls update(_:) every frame)
    override func update(_ currentTime: TimeInterval) {
        // Sync mouse position from the global cursor position.
        // NSEvent.mouseLocation is always accurate; does not depend on mouseMoved firing.
        if let v = view, let win = v.window {
            let screenPos = NSEvent.mouseLocation
            let winPos    = win.convertPoint(fromScreen: screenPos)
            let viewPos   = v.convert(winPos, from: nil)
            let scenePos  = convertPoint(fromView: viewPos)
            Mouse.Instancia.X = scenePos.x
            Mouse.Instancia.Y = CGFloat(Programa.ALTO_DE_LA_PANTALLA) - scenePos.y
        }
        gameFrame.actualizar()
        gameFrame.dibujar()
    }

    // MARK: - Mouse events
    override func mouseDown(with event: NSEvent) {
        let pos = event.location(in: self)
        Mouse.Instancia.X = pos.x
        Mouse.Instancia.Y = CGFloat(Programa.ALTO_DE_LA_PANTALLA) - pos.y
        Mouse.Instancia.presionarBoton(Mouse.BOTON_IZQ)
    }

    override func rightMouseDown(with event: NSEvent) {
        let pos = event.location(in: self)
        Mouse.Instancia.X = pos.x
        Mouse.Instancia.Y = CGFloat(Programa.ALTO_DE_LA_PANTALLA) - pos.y
        Mouse.Instancia.presionarBoton(Mouse.BOTON_DER)
    }

    override func otherMouseDown(with event: NSEvent) {
        Mouse.Instancia.presionarBoton(Mouse.BOTON_CNT)
    }

    override func mouseUp(with event: NSEvent) {
        Mouse.Instancia.soltarBoton(Mouse.BOTON_IZQ)
    }

    override func rightMouseUp(with event: NSEvent) {
        Mouse.Instancia.soltarBoton(Mouse.BOTON_DER)
    }

    override func otherMouseUp(with event: NSEvent) {
        Mouse.Instancia.soltarBoton(Mouse.BOTON_CNT)
    }

    override func mouseMoved(with event: NSEvent) {
        let pos = event.location(in: self)
        Mouse.Instancia.X = pos.x
        Mouse.Instancia.Y = CGFloat(Programa.ALTO_DE_LA_PANTALLA) - pos.y
        view?.window?.acceptsMouseMovedEvents = true
    }

    override func mouseDragged(with event: NSEvent) {
        let pos = event.location(in: self)
        Mouse.Instancia.X = pos.x
        Mouse.Instancia.Y = CGFloat(Programa.ALTO_DE_LA_PANTALLA) - pos.y
    }

    // MARK: - Keyboard events
    override func keyDown(with event: NSEvent) {
        guard !event.isARepeat else { return }
        let keyCode = Int(event.keyCode)
        if keyCode != ultimaTeclaApretada {
            ultimaTeclaApretada = keyCode
            Teclado.Instancia.presionarTecla(keyCode)
        }
    }

    override func keyUp(with event: NSEvent) {
        ultimaTeclaApretada = -1
        Teclado.Instancia.soltarTecla(Int(event.keyCode))
    }
}
