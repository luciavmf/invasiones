//
//  EstadoJuego.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of EstadoJuego.cs — active game state containing the Episodio.
//

import Foundation

class EstadoJuego: Estado {

    // MARK: - Enums
    private enum ESTADO { case INICIO, GANO, PERDIO, MENU, JUGANDO, CONFIRMACION }
    private enum MENU_ITEM: Int { case CONTINUAR = 0, SALIR = 1 }

    // MARK: - Declarations
    private var m_batalla:            Episodio?
    private var m_menuDelJuego:       Menu?
    private var m_menuDeConfirmacion: MenuDeConfirmacion?
    private var m_estado:             ESTADO = .INICIO

    // MARK: - Estado overrides

    override func iniciar() {
        m_estado = .INICIO

        m_menuDelJuego = Menu(imagen: nil, cantItem: 2, x: 0, y: 0,
                              ancla: Superficie.H_CENTRO | Superficie.V_CENTRO)
        m_menuDelJuego?.setearFuente(
            AdministradorDeRecursos.Instancia.fuentes[Definiciones.FUENTE_MENU])
        m_menuDelJuego?.agregarItem(MENU_ITEM.CONTINUAR.rawValue,
                                    Res.STR_MENU_CONTINUAR, Menu.ITEM_VISIBLE)
        m_menuDelJuego?.agregarItem(MENU_ITEM.SALIR.rawValue,
                                    Res.STR_MENU_SALIR, Menu.ITEM_VISIBLE)
    }

    override func actualizar() {
        switch m_estado {

        case .INICIO:
            m_batalla = Episodio()
            m_batalla?.iniciar()
            m_estado = .JUGANDO

            m_boton = Boton(leyenda: Res.STR_BOTON_MENU_DEL_JUEGO, fuente: nil)
            if let b = m_boton {
                b.setearPosicion(Video.Ancho - b.ancho - Boton.OFFSET_LIMITE_PANTALLA,
                                 Boton.OFFSET_LIMITE_PANTALLA, 0)
            }

            m_menuDeConfirmacion = MenuDeConfirmacion(Res.STR_CONFIRMACION_SALIR,
                                                      Res.STR_NO, Res.STR_SI)
            m_menuDeConfirmacion?.setearPosicion(0, 0, Superficie.V_CENTRO | Superficie.H_CENTRO)

        case .JUGANDO:
            m_batalla?.actualizar()
            if m_batalla?.estado == .JUGANDO {
                if m_boton?.actualizar() != 0 {
                    setearEstado(.MENU)
                }
            }
            if m_batalla?.estado == .FIN {
                maquinaDeEstados.setearElProximoEstado(.MENU_PRINCIPAL)
            }

        case .MENU:
            if let item = m_menuDelJuego?.actualizar() {
                switch MENU_ITEM(rawValue: item) {
                case .CONTINUAR: setearEstado(.JUGANDO)
                case .SALIR:     setearEstado(.CONFIRMACION)
                case .none:      break
                }
            }

        case .CONFIRMACION:
            if let resultado = m_menuDeConfirmacion?.actualizar() {
                if resultado == MenuDeConfirmacion.SELECCION.IZQUIERDO.rawValue {
                    setearEstado(.JUGANDO)
                }
                if resultado == MenuDeConfirmacion.SELECCION.DERECHO.rawValue {
                    maquinaDeEstados.setearElProximoEstado(.MENU_PRINCIPAL)
                }
            }

        case .GANO, .PERDIO:
            break
        }
    }

    override func dibujar(_ g: Video) {
        switch m_estado {

        case .JUGANDO:
            m_batalla?.dibujar(g)
            if m_batalla?.estado == .JUGANDO {
                m_boton?.dibujar(g)
            }

        case .MENU:
            m_batalla?.dibujar(g)
            m_menuDelJuego?.dibujar(g)
            g.setearFuente(AdministradorDeRecursos.Instancia.fuentes[Definiciones.FUENTE_TITULO],
                           Definiciones.COLOR_BLANCO)
            g.escribir(Res.STR_JUEGO_PAUSADO, 0, Definiciones.JUEGO_PAUSADO_Y,
                       Superficie.V_CENTRO | Superficie.H_CENTRO)

        case .CONFIRMACION:
            m_batalla?.dibujar(g)
            m_menuDeConfirmacion?.dibujar(g)

        default:
            break
        }
    }

    override func salir() {}

    // MARK: - Private

    private func setearEstado(_ estado: ESTADO) {
        m_estado = estado
    }
}

