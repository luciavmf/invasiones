// Dibujo/Superficie.swift
// Puerto de Superficie.cs — envoltorio sobre SDL_Surface.
// En SpriteKit usamos SKTexture para imágenes y SKSpriteNode para dibujar.
// Esta clase actúa como adaptador entre la API original y SpriteKit.

import SpriteKit

class Superficie {

    // MARK: - Constantes de ancla (equivalentes a los flags de SDL)
    static let H_CENTRO: Int = 1
    static let V_CENTRO: Int = 2

    // MARK: - Declaraciones
    /// La textura completa (sprite sheet o imagen completa).
    private(set) var textura: SKTexture?

    /// La sub-textura activa tras SetearClip (nil = usar textura completa).
    private(set) var texturaActual: SKTexture?

    /// Alpha actual (0.0–1.0).
    var alphaActual: CGFloat = 1.0

    /// Tamaño de la textura COMPLETA (no del clip).
    var ancho: Int { Int(textura?.size().width  ?? 0) }
    var alto:  Int { Int(textura?.size().height ?? 0) }

    /// Tamaño del clip activo (o de la textura completa si no hay clip).
    var anchoClip: Int { Int(texturaActual?.size().width  ?? textura?.size().width  ?? 0) }
    var altoClip:  Int { Int(texturaActual?.size().height ?? textura?.size().height ?? 0) }

    // MARK: - Constructores

    /// Carga una imagen desde un path absoluto.
    init(path: String, conAlpha: Bool = false) {
        let url = URL(fileURLWithPath: path)
        if let imagen = NSImage(contentsOf: url) {
            textura = SKTexture(image: imagen)
            textura?.filteringMode = .nearest
        } else {
            Log.Instancia.error("Superficie: no se pudo cargar \(path)")
        }
    }

    /// Copia constructor — comparte la misma textura (las texturas son inmutables en SpriteKit).
    init(copia: Superficie) {
        self.textura = copia.textura
    }

    /// Constructor para superficie en blanco (usada como render target — no soportada directamente).
    init(ancho: Int, alto: Int) {
        // Las superficies de render se manejarán con SKView.texture(from:) cuando sea necesario.
        textura = nil
    }

    // MARK: - Metodos

    /// Crea un SKSpriteNode listo para agregar a la escena con esta textura.
    func crearNodo() -> SKSpriteNode {
        if let tex = textura {
            return SKSpriteNode(texture: tex)
        }
        return SKSpriteNode()
    }

    /// Almacena el nivel de alpha (0–255); se aplica al nodo al dibujar.
    func setearAlpha(_ alpha: Int) {
        alphaActual = CGFloat(max(0, min(alpha, 255))) / 255.0
    }

    /// Devuelve el color del pixel en (x, y) como Int RGB.
    /// Usado para la detección isométrica de tile bajo el mouse.
    /// Requiere acceso a los datos raw de la imagen — stub por ahora.
    func colorPixel(_ x: Int, _ y: Int) -> Int {
        guard let imagen = NSImage(named: "") else { return 0 }
        _ = imagen  // suprime warning
        // TODO: implementar lectura de pixel real desde NSImage si se necesita hit-testing preciso.
        return 0
    }

    /// Establece la sub-textura activa (equivalente a SDL_SetClipRect sobre la superficie).
    /// x, y: origen del clip en píxeles de la textura completa (top-left).
    /// w, h: tamaño del clip en píxeles.
    func setearClip(_ x: Int, _ y: Int, _ w: Int, _ h: Int) {
        guard let tex = textura else { return }
        let texW = tex.size().width
        let texH = tex.size().height
        guard texW > 0, texH > 0, w > 0, h > 0 else { return }

        // SpriteKit usa coordenadas normalizadas con Y desde la base (invertido respecto al C#).
        let nx = CGFloat(x) / texW
        let ny = 1.0 - CGFloat(y + h) / texH
        let nw = CGFloat(w) / texW
        let nh = CGFloat(h) / texH

        texturaActual = SKTexture(rect: CGRect(x: nx, y: ny, width: nw, height: nh), in: tex)
        texturaActual?.filteringMode = .nearest
    }
}
