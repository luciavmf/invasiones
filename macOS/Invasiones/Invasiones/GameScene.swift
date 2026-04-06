// GameScene.swift
// Punto de entrada SpriteKit. Equivalente al loop de GameFrame.Run() en C#.
// Delega toda la lógica en GameFrame; sólo gestiona eventos de NSEvent y el tick de SpriteKit.

import SpriteKit

class GameScene: SKScene {

    // MARK: - Declaraciones
    private var gameFrame = GameFrame()
    private var ultimaTeclaApretada: Int = -1

    // MARK: - Ciclo de vida de la escena
    override func didMove(to view: SKView) {
        // Tamaño fijo de la pantalla original
        size = CGSize(width: Programa.ANCHO_DE_LA_PANTALLA, height: Programa.ALTO_DE_LA_PANTALLA)
        scaleMode = .aspectFit
        // Origen en la esquina inferior-izquierda — todo el código de Video asume (0,0) = bottom-left.
        anchorPoint = CGPoint(x: 0, y: 0)
        backgroundColor = .black

        // El original corría a 20 FPS con SDL_Delay; SpriteKit también acepta mouseMoved.
        view.preferredFramesPerSecond = Programa.FPS_POR_DEFECTO
        view.window?.acceptsMouseMovedEvents = true
        // Hacer del SKView el primer respondedor para recibir mouseMoved sin necesidad de clic previo.
        view.window?.makeFirstResponder(view)

        gameFrame.iniciarJuego(en: self)
    }

    // MARK: - Loop (SpriteKit llama a update(_:) cada frame)
    override func update(_ currentTime: TimeInterval) {
        // Sincronizar posición del mouse desde la posición global del cursor.
        // NSEvent.mouseLocation es siempre preciso; no depende de que mouseMoved dispare.
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

    // MARK: - Eventos de mouse
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

    // MARK: - Eventos de teclado
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
