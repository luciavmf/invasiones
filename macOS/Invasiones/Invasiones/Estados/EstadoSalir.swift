//
//  EstadoSalir.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of EstadoSalir.cs — exit confirmation dialog.
//

import Foundation

class EstadoSalir: Estado {

    private var m_menuDeConfirmacion: MenuDeConfirmacion?

    override func iniciar() {
        m_fondo = AdministradorDeRecursos.Instancia.obtenerImagen(Res.IMG_SPLASH)
        m_menuDeConfirmacion = MenuDeConfirmacion(Res.STR_CONFIRMACION_SALIR, Res.STR_NO, Res.STR_SI)
        m_menuDeConfirmacion?.setearPosicion(0, 0, Superficie.V_CENTRO | Superficie.H_CENTRO)
    }

    override func actualizar() {
        guard let resultado = m_menuDeConfirmacion?.actualizar() else { return }
        if resultado == MenuDeConfirmacion.SELECCION.DERECHO.rawValue {
            maquinaDeEstados.setearEstado(.FIN)
        }
        if resultado == MenuDeConfirmacion.SELECCION.IZQUIERDO.rawValue {
            maquinaDeEstados.setearElProximoEstado(.MENU_PRINCIPAL)
        }
    }

    override func dibujar(_ g: Video) {
        g.dibujar(m_fondo, 0, 0, 0)
        m_menuDeConfirmacion?.dibujar(g)
    }

    override func salir() {
        m_menuDeConfirmacion = nil
    }
}
