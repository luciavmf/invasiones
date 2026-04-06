//
//  Mouse.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Mouse.cs — singleton tracking mouse position, buttons, and drag rectangle.
//  SDL replaced by NSEvent; the custom cursor is drawn as a Superficie via Video.
//

import AppKit

class Mouse {

    // MARK: - Button constants (equivalent to SDL_BUTTON_*)
    static let BOTON_IZQ = 0
    static let BOTON_CNT = 2
    static let BOTON_DER = 1

    // MARK: - Singleton
    private static var s_instancia: Mouse?

    static var Instancia: Mouse {
        if s_instancia == nil { s_instancia = Mouse() }
        return s_instancia!
    }

    // MARK: - Declarations
    private var m_x: CGFloat = 0
    private var m_y: CGFloat = 0
    private var m_arrastrando = false
    private var m_cursorOculto = false
    private var m_terminoDeArrastrar = false
    private var m_posicionInicioArrastre: CGPoint = .zero
    private(set) var m_rectanguloArrastrado: CGRect = .zero

    /// Custom cursor surface (assigned from the state/level).
    private var m_cursorSup: Superficie?

    /// List of currently pressed buttons (indices BOTON_IZQ/DER/CNT).
    private(set) var BotonesApretados: [Int] = []

    // MARK: - Initializer (private — singleton)
    private init() {}

    // MARK: - Properties
    var X: CGFloat {
        get { m_x }
        set { m_x = max(0, min(newValue, CGFloat(Programa.ANCHO_DE_LA_PANTALLA))) }
    }

    var Y: CGFloat {
        get { m_y }
        set { m_y = max(0, min(newValue, CGFloat(Programa.ALTO_DE_LA_PANTALLA))) }
    }

    var RectanguloArrastrado: CGRect { m_rectanguloArrastrado }

    // MARK: - Button methods (called from GameScene)
    func presionarBoton(_ boton: Int) {
        if !BotonesApretados.contains(boton) {
            BotonesApretados.append(boton)
        }
    }

    func soltarBoton(_ boton: Int) {
        BotonesApretados.removeAll { $0 == boton }
    }

    /// Updates the drag state. Call once per frame from GameFrame.actualizar().
    func actualizar() {
        if BotonesApretados.contains(Mouse.BOTON_IZQ) {
            if !m_arrastrando {
                m_arrastrando = true
                m_posicionInicioArrastre = CGPoint(x: m_x, y: m_y)
            } else {
                let originX = min(m_x, m_posicionInicioArrastre.x)
                let originY = min(m_y, m_posicionInicioArrastre.y)
                let ancho   = abs(m_x - m_posicionInicioArrastre.x)
                let alto    = abs(m_y - m_posicionInicioArrastre.y)
                m_rectanguloArrastrado = CGRect(x: originX, y: originY, width: ancho, height: alto)
            }
        } else {
            m_terminoDeArrastrar = m_arrastrando
            m_arrastrando = false
            if !m_arrastrando {
                m_rectanguloArrastrado = .zero
            }
        }
    }

    func arrastrando() -> Bool  { m_arrastrando }
    func terminoDeArrastrar() -> Bool { m_terminoDeArrastrar }

    func ocultarCursor() {
        m_cursorOculto = true
        NSCursor.hide()
    }

    func mostrarCursor() {
        m_cursorOculto = false
        NSCursor.unhide()
    }

    func setearCursor(_ sup: Superficie?) {
        m_cursorSup = sup
    }

    func posicionarCursor(_ x: CGFloat, _ y: CGFloat) {
        m_x = max(0, min(x, CGFloat(Programa.ANCHO_DE_LA_PANTALLA)))
        m_y = max(0, min(y, CGFloat(Programa.ALTO_DE_LA_PANTALLA)))
    }

    /// Draws the custom cursor at the current position using the Video context.
    func dibujarCursor(en g: Video) {
        guard !m_cursorOculto, let sup = m_cursorSup else { return }
        g.dibujar(sup, Int(m_x), Int(m_y), 255, 0)
    }
}
