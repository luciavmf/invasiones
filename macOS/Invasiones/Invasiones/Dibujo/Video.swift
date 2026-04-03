// Dibujo/Video.swift
// Puerto de Video.cs — contexto de dibujo de pantalla.
// En SDL era una SDL_Surface con primitivas de blitting. En SpriteKit mantenemos un
// nodo-canvas al que añadimos hijos cada frame y limpiamos al inicio del siguiente.

import SpriteKit

class Video {

    // MARK: - Constantes de pantalla (equivalente a los statics de Video en C#)
    static let Ancho: Int = Programa.ANCHO_DE_LA_PANTALLA
    static let Alto:  Int = Programa.ALTO_DE_LA_PANTALLA

    // MARK: - Nodo canvas
    private let canvasNode: SKNode

    // MARK: - Estado de dibujo
    private var colorActual:       SKColor = .black
    private var fuenteActual:      Fuente?
    private var colorFuenteActual: SKColor = .white
    private var zPos:              CGFloat = 0

    // MARK: - Constructor
    init(escena: SKScene) {
        canvasNode = SKNode()
        escena.addChild(canvasNode)
    }

    // MARK: - Gestión del frame

    /// Elimina todos los nodos del frame anterior y reinicia el orden Z.
    func limpiar() {
        canvasNode.removeAllChildren()
        zPos = 0
    }

    // MARK: - Dibujar superficies

    /// Dibuja una superficie (o su clip activo) en coordenadas C# (x, y) con ancla.
    func dibujar(_ superficie: Superficie?, _ x: Int, _ y: Int, _ ancla: Int) {
        dibujar(superficie, x, y, 255, ancla)
    }

    /// Dibuja una superficie con transparencia explícita (alpha 0-255).
    func dibujar(_ superficie: Superficie?, _ x: Int, _ y: Int, _ alpha: Int, _ ancla: Int) {
        guard let sup = superficie,
              let tex = sup.texturaActual ?? sup.textura else { return }

        var px = x, py = y
        let fw = Int(tex.size().width)
        let fh = Int(tex.size().height)

        if (ancla & Superficie.H_CENTRO) != 0 { px += Video.Ancho / 2 - fw / 2 }
        if (ancla & Superficie.V_CENTRO) != 0 { py += Video.Alto  / 2 - fh / 2 }

        let node = SKSpriteNode(texture: tex)
        node.anchorPoint = CGPoint(x: 0, y: 1)          // ancla top-left
        node.position    = CGPoint(x: px, y: Video.Alto - py)
        node.alpha       = CGFloat(max(0, min(alpha, 255))) / 255.0
        node.zPosition   = zPos; zPos += 1
        canvasNode.addChild(node)
    }

    // MARK: - Escribir texto

    /// Escribe el string identificado por su ID (índice en Texto.Strings) con ancla.
    func escribir(_ stringId: Int, _ x: Int, _ y: Int, _ ancla: Int) {
        let strings = Texto.Strings
        guard stringId >= 0, stringId < strings.count else { return }
        escribirTexto(strings[stringId], x, y, ancla)
    }

    private func escribirTexto(_ text: String, _ x: Int, _ y: Int, _ ancla: Int) {
        var px = x, py = y
        if (ancla & Superficie.H_CENTRO) != 0 { px += Video.Ancho / 2 }
        if (ancla & Superficie.V_CENTRO) != 0 { py += Video.Alto  / 2 }

        let label = SKLabelNode()
        label.text = text
        if let font = fuenteActual?.nsFont {
            label.fontName = font.fontName
            label.fontSize = font.pointSize
        } else {
            label.fontSize = 14
        }
        label.fontColor               = colorFuenteActual
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode   = .center
        label.position  = CGPoint(x: px, y: Video.Alto - py)
        label.zPosition = zPos; zPos += 1
        canvasNode.addChild(label)
    }

    // MARK: - Primitivas de relleno

    /// Rellena un rectángulo con el color actual y alpha (0-255).
    func llenarRectangulo(_ x: Int, _ y: Int, _ w: Int, _ h: Int,
                          _ alpha: Int = 255, _ unused: Int = 0) {
        let node = SKSpriteNode(color: colorActual,
                                size: CGSize(width: w, height: h))
        node.anchorPoint = CGPoint(x: 0, y: 1)
        node.position    = CGPoint(x: x, y: Video.Alto - y)
        node.alpha       = CGFloat(max(0, min(alpha, 255))) / 255.0
        node.zPosition   = zPos; zPos += 1
        canvasNode.addChild(node)
    }

    /// Rellena toda la pantalla con un color sólido (sobrecarga sin coordenadas).
    func llenarRectangulo(_ color: Int) {
        setearColor(color)
        llenarRectangulo(0, 0, Video.Ancho, Video.Alto)
    }

    // MARK: - Estado de dibujo

    func setearColor(_ color: Int) {
        colorActual = skColor(color)
    }

    func setearFuente(_ fuente: Fuente?, _ color: Int) {
        fuenteActual      = fuente
        colorFuenteActual = skColor(color)
    }

    /// No-op: SpriteKit gestiona el doble buffer automáticamente.
    func refrescar() {}

    // MARK: - Helpers

    private func skColor(_ rgb: Int) -> SKColor {
        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >>  8) & 0xFF) / 255.0
        let b = CGFloat( rgb        & 0xFF) / 255.0
        return SKColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}
