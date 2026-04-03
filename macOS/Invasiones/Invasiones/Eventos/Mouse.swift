// Eventos/Mouse.swift
// Puerto de Mouse.cs — singleton que rastrea posición, botones y arrastre del mouse.
// SDL reemplazado por NSEvent; el cursor se gestiona como SKSpriteNode en la escena.

import SpriteKit

class Mouse {

    // MARK: - Constantes de botones (equivalentes SDL_BUTTON_*)
    static let BOTON_IZQ = 0
    static let BOTON_CNT = 2
    static let BOTON_DER = 1

    // MARK: - Singleton
    private static var s_instancia: Mouse?

    static var Instancia: Mouse {
        if s_instancia == nil { s_instancia = Mouse() }
        return s_instancia!
    }

    // MARK: - Declaraciones
    private var m_x: CGFloat = 0
    private var m_y: CGFloat = 0
    private var m_arrastrando = false
    private var m_cursorOculto = false
    private var m_terminoDeArrastrar = false
    private var m_posicionInicioArrastre: CGPoint = .zero
    private(set) var m_rectanguloArrastrado: CGRect = .zero

    /// Nodo de sprite del cursor personalizado (se asigna desde el nivel/estado).
    var m_imagenCursor: SKSpriteNode?

    /// Lista de botones actualmente presionados (índices BOTON_IZQ/DER/CNT).
    private(set) var BotonesApretados: [Int] = []

    // MARK: - Constructor (privado — singleton)
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

    // MARK: - Metodos de botones (llamados desde GameScene)
    func presionarBoton(_ boton: Int) {
        if !BotonesApretados.contains(boton) {
            BotonesApretados.append(boton)
        }
    }

    func soltarBoton(_ boton: Int) {
        BotonesApretados.removeAll { $0 == boton }
    }

    /// Actualiza el estado de arrastre. Llamar una vez por frame desde GameFrame.actualizar().
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

    func setearCursor(_ nodo: SKSpriteNode) {
        m_imagenCursor = nodo
    }

    func posicionarCursor(_ x: CGFloat, _ y: CGFloat) {
        m_x = max(0, min(x, CGFloat(Programa.ANCHO_DE_LA_PANTALLA)))
        m_y = max(0, min(y, CGFloat(Programa.ALTO_DE_LA_PANTALLA)))
    }

    /// Actualiza la posición del nodo cursor en la escena. Llamar desde GameScene tras actualizar().
    func dibujarCursor(en escena: SKScene) {
        guard !m_cursorOculto, let nodo = m_imagenCursor else { return }
        // En SpriteKit Y crece hacia arriba; convertimos desde coordenadas de pantalla.
        nodo.position = CGPoint(x: m_x, y: CGFloat(Programa.ALTO_DE_LA_PANTALLA) - m_y)
    }
}
