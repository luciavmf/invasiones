//
//  MenuDeConfirmacion.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of MenuDeConfirmacion.cs — dialog box with two buttons.
//

import Foundation

class MenuDeConfirmacion: CajaGUI {

    // MARK: - Enum
    enum SELECCION: Int {
        case NINGUNO   = -1
        case IZQUIERDO =  0
        case DERECHO   =  1
    }

    // MARK: - Declarations
    private var m_botonIzq: Boton
    private var m_botonDer: Boton

    // MARK: - Initializer
    init(_ leyenda: Int, _ boton1: Int, _ boton2: Int) {
        m_botonIzq = Boton(leyenda: boton1, fuente: nil)
        m_botonIzq.setearPosicion(0, 0, 0)
        m_botonDer = Boton(leyenda: boton2, fuente: nil)
        m_botonDer.setearPosicion(200, 200, 0)
        super.init()
        m_leyenda = leyenda
        m_ancho   = Definiciones.CONFIRMACION_ANCHO
        m_alto    = Definiciones.CONFIRMACION_ALTO
    }

    // MARK: - CajaGUI overrides

    override func setearPosicion(_ x: Int, _ y: Int, _ ancla: Int) {
        m_x = x
        m_y = y
        if (ancla & Superficie.H_CENTRO) != 0 { m_x += (Video.Ancho >> 1) - (m_ancho >> 1) }
        if (ancla & Superficie.V_CENTRO) != 0 { m_y += (Video.Alto  >> 1) - (m_alto  >> 1) }

        m_botonIzq.setearPosicion(
            m_x + Boton.OFFSET_LIMITE_PANTALLA,
            m_y + m_alto - m_botonIzq.alto - Boton.OFFSET_LIMITE_PANTALLA,
            0)
        m_botonDer.setearPosicion(
            m_x + m_ancho - m_botonDer.ancho - Boton.OFFSET_LIMITE_PANTALLA,
            m_y + m_alto  - m_botonDer.alto  - Boton.OFFSET_LIMITE_PANTALLA,
            0)
    }

    @discardableResult
    override func actualizar() -> Int {
        if m_botonIzq.actualizar() != 0 { return SELECCION.IZQUIERDO.rawValue }
        if m_botonDer.actualizar() != 0 { return SELECCION.DERECHO.rawValue   }
        return SELECCION.NINGUNO.rawValue
    }

    override func dibujar(_ g: Video) {
        g.setearColor(Definiciones.GUI_COLOR_MENUS)
        g.llenarRectangulo(m_x, m_y, m_ancho, m_alto, Definiciones.CONFIRMACION_ALPHA)

        g.setearFuente(AdministradorDeRecursos.Instancia.fuentes[Definiciones.FUENTE_MENU],
                       Definiciones.GUI_COLOR_TEXTO)
        g.escribir(m_leyenda,
                   m_x - (Video.Ancho >> 1) + (m_ancho >> 1),
                   m_y + m_alto / 5,
                   Superficie.H_CENTRO)

        m_botonIzq.dibujar(g)
        m_botonDer.dibujar(g)
    }
}
