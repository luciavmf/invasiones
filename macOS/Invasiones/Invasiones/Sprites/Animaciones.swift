//
//  Animaciones.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Animaciones.cs — animation frame controller over a sprite sheet.
//  Frames are arranged in columns (X axis) and animations in rows (Y axis).
//

import Foundation

class Animaciones {

    // MARK: - Declarations
    private(set) var animacionActual:     Int
    private      var m_pathImagen:        String
    private(set) var frameAncho:          Int
    private(set) var frameAlto:           Int
    private      var m_ticks:             Int
    private(set) var cantidadFrames:      Int = 0
    private(set) var cantidadAnimaciones: Int = 0
    var loop: Bool = true

    private var m_animacionCargada    = false
    private var m_animacionLeida      = false

    private(set) var m_ticksActuales:     Int = 0
    private(set) var frameActual:         Int = 0
    private(set) var m_imagen:            Superficie?
    private(set) var m_reproduciendo      = false
    private(set) var m_animacionTerminada = false
    private(set) var offsets:             (x: Int, y: Int) = (0, 0)

    // MARK: - Initializer principal (sin alto de frame explícito; se infiere al cargar)
    init(id: Int, path: String, frameAncho: Int, ticks: Int, offsetX: Int = 0, offsetY: Int = 0) {
        self.animacionActual = id
        self.m_pathImagen    = path
        self.frameAncho      = frameAncho
        self.frameAlto       = 0
        self.m_ticks         = ticks
        self.offsets         = (offsetX, offsetY)
        self.m_animacionLeida = (id >= 0 && id <= Res.ANIM_COUNT)
    }

    /// Initializer with explicit frame height.
    init(idx: Int, path: String, ticks: Int, anchoFrame: Int, altoFrame: Int,
         offsetX: Int = 0, offsetY: Int = 0) {
        self.animacionActual  = idx
        self.m_pathImagen     = path
        self.m_ticks          = ticks
        self.frameAncho       = anchoFrame
        self.frameAlto        = altoFrame
        self.offsets          = (offsetX, offsetY)
        self.m_animacionLeida = true
    }

    /// Copy initializer — shares the base sprite sheet but has its own clip state.
    init(copia: Animaciones) {
        self.m_pathImagen        = copia.m_pathImagen
        self.m_ticks             = copia.m_ticks
        self.frameAlto           = copia.frameAlto
        self.frameAncho          = copia.frameAncho
        self.cantidadFrames      = copia.cantidadFrames
        self.cantidadAnimaciones = copia.cantidadAnimaciones
        self.loop                = copia.loop
        self.offsets             = copia.offsets
        self.animacionActual     = -1
        self.m_animacionLeida    = copia.m_animacionLeida
        self.m_animacionCargada  = copia.m_animacionCargada

        // Each copy needs its own Superficie to have its own current texture.
        self.m_imagen = AdministradorDeRecursos.Instancia.obtenerCopiaImagen(m_pathImagen)
        setearAnimacion(0)
    }

    // MARK: - Methods

    @discardableResult
    func cargar() -> Bool {
        guard m_animacionLeida else {
            Log.Instancia.advertir("No se puede cargar la animacion \(animacionActual): no fue leída.")
            return false
        }
        guard !m_animacionCargada else {
            Log.Instancia.advertir("La animacion \(animacionActual) ya fue cargada.")
            return false
        }

        if m_imagen == nil {
            m_imagen = AdministradorDeRecursos.Instancia.obtenerImagen(m_pathImagen)
        }
        guard let img = m_imagen else {
            return false
        }

        m_animacionCargada = true
        if frameAncho == 0 { frameAncho = img.ancho }
        if frameAlto  == 0 { frameAlto  = img.alto  }
        cantidadFrames      = frameAncho > 0 ? img.ancho / frameAncho : 1
        cantidadAnimaciones = frameAlto  > 0 ? img.alto  / frameAlto  : 1

        img.setearClip(0, animacionActual * frameAlto, frameAncho, frameAlto)
        return true
    }

    func parar()      { m_reproduciendo = false }
    func reproducir() { m_reproduciendo = true  }

    func terminoDeAnimar() -> Bool { m_animacionTerminada }

    func setearFrame(_ p: Int) {
        guard p >= 0, p < cantidadFrames else { return }
        frameActual = p
        m_imagen?.setearClip(frameActual * frameAncho, animacionActual * frameAlto,
                             frameAncho, frameAlto)
    }

    @discardableResult
    func setearAnimacion(_ anim: Int) -> Bool {
        guard anim != animacionActual else { return false }
        guard anim >= 0, anim <= cantidadAnimaciones else { return false }

        animacionActual = anim
        frameActual = 0
        m_imagen?.setearClip(frameActual * frameAncho, animacionActual * frameAlto,
                             frameAncho, frameAlto)
        m_animacionTerminada = false
        return true
    }

    // MARK: - Virtual methods

    func actualizar() {
        guard m_reproduciendo else { return }

        m_ticksActuales += 1
        if m_ticksActuales >= m_ticks {
            if frameActual >= cantidadFrames {
                if loop {
                    frameActual = 0
                } else {
                    m_reproduciendo = false
                    m_animacionTerminada = true
                }
            }
            m_imagen?.setearClip(frameActual * frameAncho, animacionActual * frameAlto,
                                 frameAncho, frameAlto)
            frameActual += 1
            m_ticksActuales = 0
        }
    }

    func dibujar(_ g: Video, _ x: Int, _ y: Int, _ ancla: Int) {
        var px = x, py = y
        if (ancla & Superficie.V_CENTRO) != 0 { py += Video.Alto  / 2 - frameAlto  / 2 }
        if (ancla & Superficie.H_CENTRO) != 0 { px += Video.Ancho / 2 - frameAncho / 2 }
        g.dibujar(m_imagen, px, py, 0)
    }
}
