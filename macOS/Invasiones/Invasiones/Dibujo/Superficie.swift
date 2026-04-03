// Dibujo/Superficie.swift
// Puerto de Superficie.cs — envoltorio sobre SDL_Surface.
// En SpriteKit usamos SKTexture para imágenes y SKSpriteNode para dibujar.
// Esta clase actúa como adaptador entre la API original y SpriteKit.

import SpriteKit

class Superficie {

    // MARK: - Declaraciones
    /// La textura SpriteKit que representa esta superficie.
    private(set) var textura: SKTexture?

    /// Tamaño de la superficie.
    var ancho: Int { Int(textura?.size().width  ?? 0) }
    var alto:  Int { Int(textura?.size().height ?? 0) }

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

    /// Aplica un nivel de alpha (0–255) a la textura — se aplica al nodo al dibujar.
    /// En SpriteKit el alpha se setea en el SKSpriteNode, no en la textura.
    func setearAlpha(_ alpha: Int) {
        // No-op: el alpha se aplica en el nodo destino al momento de dibujarlo.
    }
}
