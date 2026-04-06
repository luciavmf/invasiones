// GUI/Tips.swift
// Puerto de Tips.cs — ventana flotante con consejos de juego aleatorios.

import Foundation

class Tips: CajaGUI {

    // MARK: - Constantes
    private static let INITIAL_TIP_TIME = 250
    private static let MAX_TITILA       = 40
    private static let MIN_TITILA       = 20

    // MARK: - Declaraciones
    private var m_botonTip:               Boton
    private var m_correspondeMostrarTip:  Bool = false
    private var m_cuentaTip:              Int  = 0
    private var m_cuentaTitila:           Int  = 0

    // MARK: - Constructor
    override init() {
        m_botonTip = Boton(leyenda: Res.STR_TIP_00, fuente: nil)
        super.init()

        m_botonTip.setearPosicion(
            Video.Ancho - m_botonTip.ancho - 20,
            Video.Alto  - 90 - m_botonTip.alto,
            0)

        m_ancho = Definiciones.TIPS_ANCHO
        m_alto  = Definiciones.TIPS_ALTO

        generarTipRandom()

        m_cuentaTip              = Tips.INITIAL_TIP_TIME
        m_correspondeMostrarTip  = false
    }

    // MARK: - CajaGUI

    override func setearPosicion(_ x: Int, _ y: Int, _ ancla: Int) {
        m_x = x
        m_y = y
        if (ancla & Superficie.H_CENTRO) != 0 { m_x += (Video.Ancho >> 1) - (m_ancho >> 1) }
        if (ancla & Superficie.V_CENTRO) != 0 { m_y += (Video.Alto  >> 1) - (m_alto  >> 1) }
    }

    @discardableResult
    override func actualizar() -> Int {
        m_cuentaTitila += 1

        if m_correspondeMostrarTip {
            if m_cuentaTip <= 0 {
                m_correspondeMostrarTip = false
            }
            if m_cuentaTitila > Tips.MAX_TITILA {
                m_cuentaTitila = 0
            }
        } else {
            if Int.random(in: 0..<300) == 99 {
                m_correspondeMostrarTip = true
                m_cuentaTitila          = 0
                m_cuentaTip             = Tips.INITIAL_TIP_TIME
                generarTipRandom()
            }
        }

        m_botonTip.actualizar()
        return -1  // SELECCION.NINGUNO
    }

    override func dibujar(_ g: Video) {
        guard m_correspondeMostrarTip else { return }

        if m_botonTip.debajoDelPuntero {
            g.setearColor(Definiciones.GUI_COLOR_MENUS)
            g.llenarRectangulo(m_x, m_y, m_ancho, m_alto, Definiciones.TIPS_ALPHA)
            g.setearFuente(
                AdministradorDeRecursos.Instancia.fuentes[Definiciones.FUENTE_RECORDATORIO_OBJETIVOS],
                Definiciones.GUI_COLOR_TEXTO)
            g.escribir(m_leyenda,
                       m_x - (Video.Ancho >> 1) + (m_ancho >> 1),
                       m_y + m_alto / 5,
                       Superficie.H_CENTRO)
            m_botonTip.dibujar(g)
        } else {
            m_cuentaTip -= 1
            if m_cuentaTitila > Tips.MIN_TITILA && m_cuentaTitila < Tips.MAX_TITILA {
                m_botonTip.dibujar(g)
            }
        }
    }

    // MARK: - Privado

    private func generarTipRandom() {
        m_leyenda = Int.random(in: Res.STR_TIP_01..<Res.STR_TIP_23)
    }
}
