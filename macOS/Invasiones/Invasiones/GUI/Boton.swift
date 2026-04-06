//
//  Boton.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Boton.cs — button with background image and centered text.
//

import Foundation

class Boton: CajaGUI {

    // MARK: - Constants
    static let OFFSET_LIMITE_PANTALLA = 15
    static let ALTO                   = 25
    static let ANCHO                  = 100
    static let ANCHO_MINIMO           = 10
    static let ALTO_MINIMO            = 10

    // MARK: - Declarations
    private var m_imagenSel:       Superficie?
    private(set) var debajoDelPuntero = false

    // MARK: - Initializer
    init(leyenda: Int, fuente: Fuente?) {
        super.init()

        m_alto  = Boton.ALTO
        m_ancho = Boton.ANCHO

        m_imagen    = AdministradorDeRecursos.Instancia.obtenerImagenAlpha(Res.IMG_BOTON)
        m_alto      = m_imagen?.alto  ?? Boton.ALTO
        m_ancho     = m_imagen?.ancho ?? Boton.ANCHO
        m_imagenSel = AdministradorDeRecursos.Instancia.obtenerImagenAlpha(Res.IMG_BOTON_SELECCION)
        m_fuente    = fuente ?? AdministradorDeRecursos.Instancia.fuentes[Definiciones.FUENTE_BOTON]
        m_leyenda   = leyenda
    }

    // MARK: - Methods

    override func setearPosicion(_ x: Int, _ y: Int, _ ancla: Int) {
        m_x = x
        m_y = y
        if (ancla & Superficie.V_CENTRO) != 0 { m_y += (Video.Alto  >> 1) - (m_alto  >> 1) }
        if (ancla & Superficie.H_CENTRO) != 0 { m_x += (Video.Ancho >> 1) - (m_ancho >> 1) }
    }

    @discardableResult
    override func actualizar() -> Int {
        let mx = Int(Mouse.Instancia.X)
        let my = Int(Mouse.Instancia.Y)
        debajoDelPuntero = mx > m_x && mx < m_x + m_ancho && my > m_y && my < m_y + m_alto

        if debajoDelPuntero && Mouse.Instancia.BotonesApretados.contains(Mouse.BOTON_IZQ) {
            Mouse.Instancia.soltarBoton(Mouse.BOTON_IZQ)
            return 1
        }
        return 0
    }

    override func dibujar(_ g: Video) {
        if debajoDelPuntero {
            if m_imagenSel != nil {
                g.dibujar(m_imagenSel, m_x, m_y, 0)
            } else {
                g.setearColor(Definiciones.GUI_COLOR_SELECCION)
                g.llenarRectangulo(m_x, m_y, m_ancho, m_alto, Definiciones.GUI_ALPHA)
            }
        } else {
            if m_imagen != nil {
                g.dibujar(m_imagen, m_x, m_y, 0)
            } else {
                g.setearColor(Definiciones.GUI_COLOR_MENUS)
                g.llenarRectangulo(m_x, m_y, m_ancho, m_alto, Definiciones.GUI_ALPHA)
            }
        }

        g.setearFuente(m_fuente, Definiciones.GUI_COLOR_TEXTO)
        g.escribir(m_leyenda,
                   m_x - Video.Ancho / 2 + m_ancho / 2,
                   m_y - Video.Alto  / 2 + m_alto  / 2,
                   Superficie.H_CENTRO | Superficie.V_CENTRO)
    }

    func setearAlto(_ alto: Int) {
        if m_imagen == nil { m_alto = alto }
    }

    func setearAncho(_ ancho: Int) {
        if m_imagen == nil { m_ancho = ancho }
    }
}
