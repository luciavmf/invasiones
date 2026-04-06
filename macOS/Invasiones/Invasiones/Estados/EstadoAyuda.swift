// Estados/EstadoAyuda.swift
// Puerto de EstadoAyuda.cs — pantallas de ayuda/tutorial con animaciones.

import Foundation

class EstadoAyuda: Estado {

    // MARK: - Sub-estados
    private enum SUBESTADO: Int {
        case SELECCIONAR = 0, MOVER, ATACAR, OBJETIVO, SCROLL, HUD, SANAR, TIPS, GANAR
        static let TOTAL = 9
    }

    // MARK: - Declaraciones
    private var m_subestado:        SUBESTADO = .SELECCIONAR
    private var m_botonAtras:       Boton?
    private var m_botonSig:         Boton?
    private var m_screenshotActual: Animaciones?

    // MARK: - Métodos

    override func iniciar() {
        m_fondo = AdministradorDeRecursos.Instancia.obtenerImagen(Res.IMG_FONDO)

        let fnt = AdministradorDeRecursos.Instancia.fuentes[Definiciones.FNT.SANS18.rawValue]

        m_boton = Boton(leyenda: Res.STR_BOTON_MENU, fuente: fnt)
        m_boton?.setearPosicion(
            Video.Ancho - (m_boton?.ancho ?? 0) - Boton.OFFSET_LIMITE_PANTALLA,
            Video.Alto  - (m_boton?.alto  ?? 0) - Boton.OFFSET_LIMITE_PANTALLA, 0)

        m_botonSig = Boton(leyenda: Res.STR_SIGUIENTE, fuente: fnt)
        m_botonSig?.setearPosicion(
            Video.Ancho - (m_botonSig?.ancho ?? 0) - Boton.OFFSET_LIMITE_PANTALLA,
            Video.Alto  - (m_botonSig?.alto  ?? 0) - Boton.OFFSET_LIMITE_PANTALLA, 0)

        m_botonAtras = Boton(leyenda: Res.STR_ATRAS, fuente: fnt)
        m_botonAtras?.setearPosicion(
            Video.Ancho - (m_botonSig?.ancho ?? 0) * 2 - Boton.OFFSET_LIMITE_PANTALLA,
            Video.Alto  - (m_botonSig?.alto  ?? 0) - Boton.OFFSET_LIMITE_PANTALLA, 0)

        m_subestado = .SELECCIONAR
        cargarScreenshot(m_subestado)
    }

    override func actualizar() {
        if m_boton?.actualizar() != 0 {
            let siguiente = m_subestado.rawValue + 1
            if siguiente > SUBESTADO.GANAR.rawValue {
                maquinaDeEstados.setearElProximoEstado(.MENU_PRINCIPAL)
            } else if let sig = SUBESTADO(rawValue: siguiente) {
                m_subestado = sig
                cargarScreenshot(sig)
            }
        }

        if m_botonAtras?.actualizar() != 0, m_subestado != .SELECCIONAR {
            let anterior = m_subestado.rawValue - 1
            if let ant = SUBESTADO(rawValue: anterior) {
                m_subestado = ant
                cargarScreenshot(ant)
            }
        }

        m_screenshotActual?.actualizar()
    }

    override func dibujar(_ g: Video) {
        g.dibujar(m_fondo, 0, 0, 0)

        g.setearFuente(AdministradorDeRecursos.Instancia.fuentes[Definiciones.FUENTE_TITULO],
                       Definiciones.COLOR_TITULO)
        g.escribir(Res.STR_MENU_AYUDA, 0, Definiciones.TITULO_Y, Superficie.H_CENTRO)

        if m_subestado.rawValue < SUBESTADO.TOTAL {
            g.setearFuente(AdministradorDeRecursos.Instancia.fuentes[Definiciones.FUENTE_TITULO_AYUDA],
                           Definiciones.GUI_COLOR_TEXTO)
            g.escribir(Res.STR_MENU_AYUDA_TEXTO_SELECCIONAR_01 + m_subestado.rawValue * 2,
                       0, Definiciones.TEXTO_AYUDA_ITEM_Y, Superficie.H_CENTRO)

            g.setearFuente(AdministradorDeRecursos.Instancia.fuentes[Definiciones.FUENTE_AYUDA],
                           Definiciones.GUI_COLOR_TEXTO)
            g.escribir(Res.STR_MENU_AYUDA_TEXTO_SELECCIONAR_02 + m_subestado.rawValue * 2,
                       0, Definiciones.TEXTO_AYUDA_Y, Superficie.H_CENTRO)
        }

        m_screenshotActual?.dibujar(g, 0, 150, Superficie.H_CENTRO | Superficie.V_CENTRO)

        if m_subestado != .SELECCIONAR { m_botonAtras?.dibujar(g) }
        if m_subestado != .GANAR {
            m_botonSig?.dibujar(g)
        } else {
            m_boton?.dibujar(g)
        }
    }

    override func salir() {}

    // MARK: - Privado

    private func cargarScreenshot(_ sub: SUBESTADO) {
        let animIdx = Res.ANIM_AYUDA_SELECCION + sub.rawValue
        let anims = AdministradorDeRecursos.Instancia.animaciones
        guard animIdx < anims.count, let anim = anims[animIdx] else {
            m_screenshotActual = nil
            return
        }
        anim.cargar()
        anim.reproducir()
        anim.loop = true
        m_screenshotActual = anim
    }
}
