//
//  Animation.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Animaciones.cs — animation frame controller over a sprite sheet.
//  Frames are arranged in columns (X axis) and animations in rows (Y axis).
//

import Foundation

class Animation {

    // MARK: - Declarations
    private(set) var currentAnimation:     Int
    private      var m_imagePath:        String
    private(set) var frameWidth:          Int
    private(set) var frameHeight:           Int
    private      var m_ticks:             Int
    private(set) var frameCount:      Int = 0
    private(set) var animationCount: Int = 0
    var loop: Bool = true

    private var m_animLoaded    = false
    private var m_animRead      = false

    private(set) var m_currentTicks:     Int = 0
    private(set) var currentFrame:         Int = 0
    private(set) var m_image:            Surface?
    private(set) var m_isPlaying      = false
    private(set) var m_animDone = false
    private(set) var offsets:             (x: Int, y: Int) = (0, 0)

    // MARK: - Initializer principal (sin height de frame explícito; se infiere al load)
    init(id: Int, path: String, frameAncho: Int, ticks: Int, offsetX: Int = 0, offsetY: Int = 0) {
        self.currentAnimation = id
        self.m_imagePath    = path
        self.frameWidth      = frameAncho
        self.frameHeight       = 0
        self.m_ticks         = ticks
        self.offsets         = (offsetX, offsetY)
        self.m_animRead = (id >= 0 && id <= Res.ANIM_COUNT)
    }

    /// Initializer with explicit frame height.
    init(idx: Int, path: String, ticks: Int, anchoFrame: Int, altoFrame: Int,
         offsetX: Int = 0, offsetY: Int = 0) {
        self.currentAnimation  = idx
        self.m_imagePath     = path
        self.m_ticks          = ticks
        self.frameWidth       = anchoFrame
        self.frameHeight        = altoFrame
        self.offsets          = (offsetX, offsetY)
        self.m_animRead = true
    }

    /// Copy initializer — shares the base sprite sheet but has its own clip state.
    init(copia: Animation) {
        self.m_imagePath        = copia.m_imagePath
        self.m_ticks             = copia.m_ticks
        self.frameHeight           = copia.frameHeight
        self.frameWidth          = copia.frameWidth
        self.frameCount      = copia.frameCount
        self.animationCount = copia.animationCount
        self.loop                = copia.loop
        self.offsets             = copia.offsets
        self.currentAnimation     = -1
        self.m_animRead    = copia.m_animRead
        self.m_animLoaded  = copia.m_animLoaded

        // Each copy needs its own Surface to have its own current texture.
        self.m_image = ResourceManager.shared.getCopyOfImage(m_imagePath)
        setAnimation(0)
    }

    // MARK: - Methods

    @discardableResult
    func load() -> Bool {
        guard m_animRead else {
            Log.shared.warn("No se puede load la animation \(currentAnimation): no fue leída.")
            return false
        }
        guard !m_animLoaded else {
            Log.shared.warn("La animation \(currentAnimation) ya fue cargada.")
            return false
        }

        if m_image == nil {
            m_image = ResourceManager.shared.getImage(m_imagePath)
        }
        guard let img = m_image else {
            return false
        }

        m_animLoaded = true
        if frameWidth == 0 { frameWidth = img.width }
        if frameHeight  == 0 { frameHeight  = img.height  }
        frameCount      = frameWidth > 0 ? img.width / frameWidth : 1
        animationCount = frameHeight  > 0 ? img.height  / frameHeight  : 1

        img.setClip(0, currentAnimation * frameHeight, frameWidth, frameHeight)
        return true
    }

    func stop() {
        m_isPlaying = false
    }

    func play() {
        m_isPlaying = true
    }

    func isAnimationDone() -> Bool {
        m_animDone
    }

    func setFrame(_ p: Int) {
        guard p >= 0, p < frameCount else { return }
        currentFrame = p
        m_image?.setClip(currentFrame * frameWidth, currentAnimation * frameHeight,
                             frameWidth, frameHeight)
    }

    @discardableResult
    func setAnimation(_ anim: Int) -> Bool {
        guard anim != currentAnimation else { return false }
        guard anim >= 0, anim <= animationCount else { return false }

        currentAnimation = anim
        currentFrame = 0
        m_image?.setClip(currentFrame * frameWidth, currentAnimation * frameHeight,
                             frameWidth, frameHeight)
        m_animDone = false
        return true
    }

    // MARK: - Virtual methods

    func update() {
        guard m_isPlaying else { return }

        m_currentTicks += 1
        if m_currentTicks >= m_ticks {
            if currentFrame >= frameCount {
                if loop {
                    currentFrame = 0
                } else {
                    m_isPlaying = false
                    m_animDone = true
                }
            }
            m_image?.setClip(currentFrame * frameWidth, currentAnimation * frameHeight,
                                 frameWidth, frameHeight)
            currentFrame += 1
            m_currentTicks = 0
        }
    }

    func draw(_ g: Video, _ x: Int, _ y: Int, _ anchor: Int) {
        var px = x, py = y
        if (anchor & Surface.centerVertical) != 0 { py += Video.height  / 2 - frameHeight  / 2 }
        if (anchor & Surface.centerHorizontal) != 0 { px += Video.width / 2 - frameWidth / 2 }
        g.draw(m_image, px, py, 0)
    }
}
