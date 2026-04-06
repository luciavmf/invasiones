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
    var animations: [Animation?] = []
    private var currentAnim: Animation?
    private var currentAnimId: Int = -1

    // MARK: - Initializeres
    init() {}

    /// Copy initializer: clones all animations from the original sprite.
    init(copia: Sprite) {
        animations = copia.animations.map { $0.map { Animation(copia: $0) } }
        currentAnim = animations.compactMap { $0 }.first
    }

    // MARK: - Properties
    var loop: Bool {
        get { currentAnim?.loop ?? false }
        set { currentAnim?.loop = newValue }
    }

    var frameAncho: Int { currentAnim?.frameWidth ?? 0 }
    var frameAlto: Int { currentAnim?.frameHeight ?? 0 }
    var frameCount: Int { currentAnim?.frameCount ?? 0 }
    var image: Surface? { currentAnim?.image }
    var offsets: (x: Int, y: Int) { currentAnim?.offsets ?? (0, 0) }
    var currentFrame: Int { currentAnim?.currentFrame ?? 0 }
    var currentAnimation: Int { currentAnim?.currentAnimation ?? 0 }

    // MARK: - Methods

    func update() {
        currentAnim?.update()
    }

    @discardableResult
    func setAnimation(_ anim: Int) -> Bool {
        guard anim != currentAnimId else { return false }
        currentAnimId = anim

        var offset = 0
        var prevAnimCount = 0

        for animObj in animations.compactMap({ $0 }) {
            if anim >= prevAnimCount &&
               anim - prevAnimCount < animObj.animationCount {
                currentAnim = animObj
                offset = prevAnimCount
            }
            prevAnimCount += animObj.animationCount
        }

        currentAnim?.setAnimation(anim - offset)
        return true
    }

    @discardableResult
    func addAnimation(_ i: Int, _ anim: Animation) -> Bool {
        guard !animations.isEmpty else {
            Log.shared.error("No se carga la unit: la cantidad de animaciones no está seteada.")
            return false
        }
        guard i < animations.count else {
            Log.shared.debug("Animacion con index invalido: \(i)")
            return false
        }
        animations[i] = anim
        return true
    }

    /// Pre-allocates N animation slots (equivalent to `new Animation[N]` in C#).
    func reserveSlots(_ count: Int) {
        animations = Array(repeating: nil, count: count)
    }

    func draw(_ g: Video, _ x: Int, _ y: Int) {
        guard let img = currentAnim?.image else { return }
        g.draw(img, x, y, 0)
    }

    @discardableResult
    func load() -> Bool {
        var ok = true
        for anim in animations.compactMap({ $0 }) {
            if !anim.load() { ok = false }
        }
        currentAnim = animations.compactMap({ $0 }).first
        return ok
    }

    func play() { currentAnim?.play() }
    func stop() { currentAnim?.stop() }

    func isAnimationDone() -> Bool { currentAnim?.isAnimationDone() ?? false }

    func setFrame(_ p: Int) { currentAnim?.setFrame(p) }
}
