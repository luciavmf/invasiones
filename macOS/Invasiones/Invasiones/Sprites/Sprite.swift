//
//  Sprite.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Sprite.cs — container of animations for a game sprite.
//  Manages an indexed array of Animation and delegates to the active animation.
//

import Foundation

class Sprite {

    // MARK: - Declarations
    var m_animations: [Animation?] = []
    private var m_currentAnim:   Animation?
    private var m_currentAnimId: Int = -1

    // MARK: - Initializeres
    init() {}

    /// Copy initializer: clones all animations from the original sprite.
    init(copia: Sprite) {
        m_animations    = copia.m_animations.map { $0.map { Animation(copia: $0) } }
        m_currentAnim = m_animations.compactMap { $0 }.first
    }

    // MARK: - Properties
    var loop: Bool {
        get { m_currentAnim?.loop ?? false }
        set { m_currentAnim?.loop = newValue }
    }

    var frameAncho:       Int          { m_currentAnim?.frameWidth          ?? 0    }
    var frameAlto:        Int          { m_currentAnim?.frameHeight           ?? 0    }
    var frameCount: Int          { m_currentAnim?.frameCount      ?? 0    }
    var image:           Surface?  { m_currentAnim?.m_image                   }
    var offsets:          (x: Int, y: Int) { m_currentAnim?.offsets ?? (0, 0) }
    var currentFrame:      Int          { m_currentAnim?.currentFrame         ?? 0    }
    var currentAnimation:  Int          { m_currentAnim?.currentAnimation     ?? 0    }

    // MARK: - Methods

    func update() {
        m_currentAnim?.update()
    }

    @discardableResult
    func setAnimation(_ anim: Int) -> Bool {
        guard anim != m_currentAnimId else { return false }
        m_currentAnimId = anim

        var offset = 0
        var prevAnimCount = 0

        for animObj in m_animations.compactMap({ $0 }) {
            if anim >= prevAnimCount &&
               anim - prevAnimCount < animObj.animationCount {
                m_currentAnim = animObj
                offset = prevAnimCount
            }
            prevAnimCount += animObj.animationCount
        }

        m_currentAnim?.setAnimation(anim - offset)
        return true
    }

    @discardableResult
    func addAnimation(_ i: Int, _ anim: Animation) -> Bool {
        guard !m_animations.isEmpty else {
            Log.shared.error("No se carga la unit: la cantidad de animaciones no está seteada.")
            return false
        }
        guard i < m_animations.count else {
            Log.shared.debug("Animacion con index invalido: \(i)")
            return false
        }
        m_animations[i] = anim
        return true
    }

    /// Pre-allocates N animation slots (equivalent to `new Animation[N]` in C#).
    func reserveSlots(_ count: Int) {
        m_animations = Array(repeating: nil, count: count)
    }

    func draw(_ g: Video, _ x: Int, _ y: Int) {
        guard let img = m_currentAnim?.m_image else { return }
        g.draw(img, x, y, 0)
    }

    @discardableResult
    func load() -> Bool {
        var ok = true
        for anim in m_animations.compactMap({ $0 }) {
            if !anim.load() { ok = false }
        }
        m_currentAnim = m_animations.compactMap({ $0 }).first
        return ok
    }

    func play() { m_currentAnim?.play() }
    func stop()      { m_currentAnim?.stop() }

    func isAnimationDone() -> Bool { m_currentAnim?.isAnimationDone() ?? false }

    func setFrame(_ p: Int) { m_currentAnim?.setFrame(p) }
}
