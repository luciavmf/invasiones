// Estados/EstadoLogo.swift
// Puerto de EstadoLogo.cs — pantalla de logo con fade-in antes de pasar al menú.

import Foundation

class EstadoLogo: Estado {

    // MARK: - Constantes
    private let LOGO_INICIO_CNT = 20
    private let LOGO_TIEMPO_CNT = 70

    // MARK: - Declaraciones
    private var m_logo:          Superficie?
    private var m_transparencia: Int = 10

    // MARK: - Constructor
    override init(_ sm: MaquinaDeEstados) {
        super.init(sm)
        m_cuenta = 0
    }

    // MARK: - Métodos

    override func iniciar() {}

    override func actualizar() {
        if m_cuenta == 0 {
            m_logo = AdministradorDeRecursos.Instancia.obtenerImagenAlpha(Res.IMG_LOGO)
            m_transparencia = 10
        } else if m_cuenta > LOGO_INICIO_CNT + LOGO_TIEMPO_CNT {
            maquinaDeEstados.setearElProximoEstado(.MENU_PRINCIPAL)
        }
        m_cuenta += 1
    }

    override func dibujar(_ g: Video) {
        g.llenarRectangulo(Definiciones.COLOR_NEGRO)

        if m_cuenta > LOGO_INICIO_CNT && m_cuenta < LOGO_TIEMPO_CNT {
            if m_transparencia < 255 - 10 {
                m_transparencia += 10
            }
            g.dibujar(m_logo, 0, 0, m_transparencia, Superficie.H_CENTRO | Superficie.V_CENTRO)
        }
    }

    override func salir() {
        m_logo = nil
    }
}
