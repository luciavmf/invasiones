//
//  Sprite.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Sprite.cs — container of animations for a game sprite.
//  Manages an indexed array of Animaciones and delegates to the active animation.
//

import Foundation

class Sprite {

    // MARK: - Declarations
    var m_animaciones: [Animaciones?] = []
    private var m_animacionActual:   Animaciones?
    private var m_idAnimacionActual: Int = -1

    // MARK: - Initializeres
    init() {}

    /// Copy initializer: clones all animations from the original sprite.
    init(copia: Sprite) {
        m_animaciones    = copia.m_animaciones.map { $0.map { Animaciones(copia: $0) } }
        m_animacionActual = m_animaciones.compactMap { $0 }.first
    }

    // MARK: - Properties
    var loop: Bool {
        get { m_animacionActual?.loop ?? false }
        set { m_animacionActual?.loop = newValue }
    }

    var frameAncho:       Int          { m_animacionActual?.frameAncho          ?? 0    }
    var frameAlto:        Int          { m_animacionActual?.frameAlto           ?? 0    }
    var cantidadDeFrames: Int          { m_animacionActual?.cantidadFrames      ?? 0    }
    var imagen:           Superficie?  { m_animacionActual?.m_imagen                   }
    var offsets:          (x: Int, y: Int) { m_animacionActual?.offsets ?? (0, 0) }
    var frameActual:      Int          { m_animacionActual?.frameActual         ?? 0    }
    var animacionActual:  Int          { m_animacionActual?.animacionActual     ?? 0    }

    // MARK: - Methods

    func actualizar() {
        m_animacionActual?.actualizar()
    }

    @discardableResult
    func setearAnimacion(_ anim: Int) -> Bool {
        guard anim != m_idAnimacionActual else { return false }
        m_idAnimacionActual = anim

        var resta = 0
        var animacionesAnteriores = 0

        for animObj in m_animaciones.compactMap({ $0 }) {
            if anim >= animacionesAnteriores &&
               anim - animacionesAnteriores < animObj.cantidadAnimaciones {
                m_animacionActual = animObj
                resta = animacionesAnteriores
            }
            animacionesAnteriores += animObj.cantidadAnimaciones
        }

        m_animacionActual?.setearAnimacion(anim - resta)
        return true
    }

    @discardableResult
    func agregarAnimacion(_ i: Int, _ anim: Animaciones) -> Bool {
        guard !m_animaciones.isEmpty else {
            Log.Instancia.error("No se carga la unidad: la cantidad de animaciones no está seteada.")
            return false
        }
        guard i < m_animaciones.count else {
            Log.Instancia.debug("Animacion con indice invalido: \(i)")
            return false
        }
        m_animaciones[i] = anim
        return true
    }

    /// Pre-allocates N animation slots (equivalent to `new Animaciones[N]` in C#).
    func reservarSlots(_ count: Int) {
        m_animaciones = Array(repeating: nil, count: count)
    }

    func dibujar(_ g: Video, _ x: Int, _ y: Int) {
        guard let img = m_animacionActual?.m_imagen else { return }
        g.dibujar(img, x, y, 0)
    }

    @discardableResult
    func cargar() -> Bool {
        var ok = true
        for anim in m_animaciones.compactMap({ $0 }) {
            if !anim.cargar() { ok = false }
        }
        m_animacionActual = m_animaciones.compactMap({ $0 }).first
        return ok
    }

    func reproducir() { m_animacionActual?.reproducir() }
    func parar()      { m_animacionActual?.parar() }

    func terminoDeAnimar() -> Bool { m_animacionActual?.terminoDeAnimar() ?? false }

    func setearFrame(_ p: Int) { m_animacionActual?.setearFrame(p) }
}
