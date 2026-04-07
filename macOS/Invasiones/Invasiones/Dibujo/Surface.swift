//
//  Surface.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Superficie.cs — wrapper over SDL_Surface.
//  In SpriteKit we use SKTexture for images and SKSpriteNode for drawing.
//  Acts as an adapter between the original API and SpriteKit.
//

import SpriteKit

/// Wrapper over a SpriteKit texture, mirroring the SDL_Surface-based Superficie class.
/// Used by all classes that draw images. Supports anchor-point-based positioning,
/// sub-texture clipping, and per-surface alpha.
class Surface {

    // MARK: - Anchor constants (equivalent to SDL flags)
    /// Anchor flag: centre horizontally.
    static let centerHorizontal: Int = 1
    /// Anchor flag: centre vertically.
    static let centerVertical: Int = 2

    // MARK: - Declarations
    /// The full texture (sprite sheet or complete image).
    private(set) var texture: SKTexture?

    /// The active sub-texture after SetearClip (nil = use full texture).
    private(set) var currentTexture: SKTexture?

    /// Current alpha (0.0–1.0).
    var currentAlpha: CGFloat = 1.0

    /// Width of the full texture in pixels (not the clip).
    var width: Int { Int(texture?.size().width ?? 0) }
    /// Height of the full texture in pixels (not the clip).
    var height: Int { Int(texture?.size().height ?? 0) }

    /// Width of the active clip, or the full texture width if no clip is set.
    var clipWidth: Int { Int(currentTexture?.size().width ?? texture?.size().width ?? 0) }
    /// Height of the active clip, or the full texture height if no clip is set.
    var clipHeight: Int { Int(currentTexture?.size().height ?? texture?.size().height ?? 0) }

    // MARK: - Initializers

    /// Loads an image from an absolute path.
    init(path: String, withAlpha: Bool = false) {
        let url = URL(fileURLWithPath: path)
        if let image = NSImage(contentsOf: url) {
            texture = SKTexture(image: image)
            texture?.filteringMode = .nearest
        } else {
            Log.shared.error("Surface: no se pudo load \(path)")
        }
    }

    /// Copy constructor — shares the same texture (textures are immutable in SpriteKit).
    init(copia: Surface) {
        self.texture = copia.texture
    }

    /// Blank surface constructor (used as a render target — not directly supported).
    init(width: Int, height: Int) {
        // Render surfaces will be handled with SKView.texture(from:) when needed.
        texture = nil
    }

    // MARK: - Methods

    /// Creates an SKSpriteNode ready to add to the scene with this texture.
    func createNode() -> SKSpriteNode {
        if let tex = texture {
            return SKSpriteNode(texture: tex)
        }
        return SKSpriteNode()
    }

    /// Stores the alpha level (0–255); applied to the node when drawing.
    func setAlpha(alpha: Int) {
        currentAlpha = CGFloat(max(0, min(alpha, 255))) / 255.0
    }

    /// Returns the pixel colour at (x, y) as an RGB Int.
    /// Used for isometric tile detection under the mouse.
    /// Requires access to raw image data — stub for now.
    func pixelColor(x: Int, y: Int) -> Int {
        guard let image = NSImage(named: "") else { return 0 }
        _ = image  // suprime warning
        // TODO: implementar lectura de pixel real desde NSImage si se necesita hit-testing preciso.
        return 0
    }

    /// Sets the active sub-texture (equivalent to SDL_SetClipRect on the surface).
    /// x, y: clip origin in pixels of the full texture (top-left).
    /// w, h: clip size in pixels.
    func setClip(x: Int, y: Int, w: Int, h: Int) {
        guard let tex = texture else { return }
        let texW = tex.size().width
        let texH = tex.size().height
        guard texW > 0, texH > 0, w > 0, h > 0 else { return }

        // SpriteKit uses normalised coordinates with Y from the bottom (inverted relative to C#).
        let nx = CGFloat(x) / texW
        let ny = 1.0 - CGFloat(y + h) / texH
        let nw = CGFloat(w) / texW
        let nh = CGFloat(h) / texH

        currentTexture = SKTexture(rect: CGRect(x: nx, y: ny, width: nw, height: nh), in: tex)
        currentTexture?.filteringMode = .nearest
    }
}
