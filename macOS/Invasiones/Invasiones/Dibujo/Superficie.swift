//
//  Superficie.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Superficie.cs — wrapper over SDL_Surface.
//  In SpriteKit we use SKTexture for images and SKSpriteNode for drawing.
//  Acts as an adapter between the original API and SpriteKit.
//

import SpriteKit

class Superficie {

    // MARK: - Anchor constants (equivalent to SDL flags)
    static let H_CENTRO: Int = 1
    static let V_CENTRO: Int = 2

    // MARK: - Declarations
    /// The full texture (sprite sheet or complete image).
    private(set) var textura: SKTexture?

    /// The active sub-texture after SetearClip (nil = use full texture).
    private(set) var texturaActual: SKTexture?

    /// Current alpha (0.0–1.0).
    var alphaActual: CGFloat = 1.0

    /// Size of the FULL texture (not the clip).
    var ancho: Int { Int(textura?.size().width  ?? 0) }
    var alto:  Int { Int(textura?.size().height ?? 0) }

    /// Size of the active clip (or the full texture if no clip is set).
    var anchoClip: Int { Int(texturaActual?.size().width  ?? textura?.size().width  ?? 0) }
    var altoClip:  Int { Int(texturaActual?.size().height ?? textura?.size().height ?? 0) }

    // MARK: - Initializers

    /// Loads an image from an absolute path.
    init(path: String, conAlpha: Bool = false) {
        let url = URL(fileURLWithPath: path)
        if let imagen = NSImage(contentsOf: url) {
            textura = SKTexture(image: imagen)
            textura?.filteringMode = .nearest
        } else {
            Log.Instancia.error("Superficie: no se pudo cargar \(path)")
        }
    }

    /// Copy constructor — shares the same texture (textures are immutable in SpriteKit).
    init(copia: Superficie) {
        self.textura = copia.textura
    }

    /// Blank surface constructor (used as a render target — not directly supported).
    init(ancho: Int, alto: Int) {
        // Render surfaces will be handled with SKView.texture(from:) when needed.
        textura = nil
    }

    // MARK: - Methods

    /// Creates an SKSpriteNode ready to add to the scene with this texture.
    func crearNodo() -> SKSpriteNode {
        if let tex = textura {
            return SKSpriteNode(texture: tex)
        }
        return SKSpriteNode()
    }

    /// Stores the alpha level (0–255); applied to the node when drawing.
    func setearAlpha(_ alpha: Int) {
        alphaActual = CGFloat(max(0, min(alpha, 255))) / 255.0
    }

    /// Returns the pixel colour at (x, y) as an RGB Int.
    /// Used for isometric tile detection under the mouse.
    /// Requires access to raw image data — stub for now.
    func colorPixel(_ x: Int, _ y: Int) -> Int {
        guard let imagen = NSImage(named: "") else { return 0 }
        _ = imagen  // suprime warning
        // TODO: implementar lectura de pixel real desde NSImage si se necesita hit-testing preciso.
        return 0
    }

    /// Sets the active sub-texture (equivalent to SDL_SetClipRect on the surface).
    /// x, y: clip origin in pixels of the full texture (top-left).
    /// w, h: clip size in pixels.
    func setearClip(_ x: Int, _ y: Int, _ w: Int, _ h: Int) {
        guard let tex = textura else { return }
        let texW = tex.size().width
        let texH = tex.size().height
        guard texW > 0, texH > 0, w > 0, h > 0 else { return }

        // SpriteKit uses normalised coordinates with Y from the bottom (inverted relative to C#).
        let nx = CGFloat(x) / texW
        let ny = 1.0 - CGFloat(y + h) / texH
        let nw = CGFloat(w) / texW
        let nh = CGFloat(h) / texH

        texturaActual = SKTexture(rect: CGRect(x: nx, y: ny, width: nw, height: nh), in: tex)
        texturaActual?.filteringMode = .nearest
    }
}
