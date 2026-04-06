// Estados/EstadoOpciones.swift
// Puerto de EstadoOpciones.cs — pantalla de opciones (actualmente sólo muestra título y vuelve).

import Foundation

class EstadoOpciones: Estado {

    override func iniciar() {
        m_fondo = AdministradorDeRecursos.Instancia.obtenerImagen(Res.IMG_FONDO)
        m_boton = Boton(leyenda: Res.STR_BOTON_MENU, fuente: nil)
        m_boton?.setearPosicion(
            Video.Ancho - (m_boton?.ancho ?? 0) - Boton.OFFSET_LIMITE_PANTALLA,
            Video.Alto  - (m_boton?.alto  ?? 0) - Boton.OFFSET_LIMITE_PANTALLA, 0)
    }

    override func actualizar() {
        if m_boton?.actualizar() != 0 {
            maquinaDeEstados.setearElProximoEstado(.MENU_PRINCIPAL)
        }
    }

    override func dibujar(_ g: Video) {
        g.dibujar(m_fondo, 0, 0, 0)
        g.setearFuente(AdministradorDeRecursos.Instancia.fuentes[Definiciones.FUENTE_TITULO],
                       Definiciones.GUI_COLOR_TEXTO)
        g.escribir(Res.STR_MENU_OPCIONES, 0, Definiciones.TITULO_Y, Superficie.H_CENTRO)
        m_boton?.dibujar(g)
    }

    override func salir() {}
}
