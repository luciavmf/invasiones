using System;
using System.Collections.Generic;
using System.Text;
using Invasiones.Dibujo;
using Invasiones.Recursos;
using Invasiones.Debug;

namespace Invasiones.Nivel
{
    public partial class Episodio
    {

        /// <summary>
        /// Actualiza el string que se va a mostrar en pantalla con el nuevo objetivo.
        /// </summary>
        private void ActualizarEstadoMostrarIntroduccion()
        {
            if (m_cuenta == 0)
            {
                m_boton.SetearPosicion(0, Definiciones.BOTON_OBJETIVOS_Y, Superficie.H_CENTRO);
            }

            m_cuenta++;

            if (m_boton.Actualizar() != 0)
            {
                m_paginaActual++;
                if (m_paginaActual == Definiciones.PAGINAS_POR_INTRO - 1)
                {
                    SetearEstado(ESTADO.JUGANDO);
                }
            }
        }

        /// <summary>
        /// Actualiza los objetivos a cumplir
        /// </summary>
        private void SetearNuevoObjetivo()
        {
            Log.Instancia.Debug("Le seteo un nuevo objetivo........");

            m_mostrarPopupObjetivo = true;

            int batallaActual = m_nivelActual.NroBatallaActual;
            m_objetivo = m_nivelActual.ProximoObjetivo();

            if (m_nivelActual.NroBatallaActual != batallaActual)
            {
                Log.Instancia.Debug("Pase del nivelllllllll");
                SetearEstado(ESTADO.MOSTRAR_INTRODUCCION);
            }
            m_mostrarPopupObjetivo = true;
            m_cuentaMostrarObjetivo = 0;

            m_jugador.SetearObjetivo(m_objetivo);

            if (m_objetivo == null)
            {
                SetearEstado(ESTADO.GANO);
                return;
            }
        }

        /// <summary>
        /// Muestra el objetivo de la batalla por pantalla.
        /// </summary>
        /// <param name="g">El video en donde dibujar.</param>
        private void DibujarEstadoMostrarIntroduccion(Video g)
        {
            DibujarEstadoJugando(g);

            g.SetearColor(Definiciones.COLOR_OBJETIVOS);

            g.LlenarRectangulo(0, -(m_hud.Alto >> 1), Video.Ancho - (Definiciones.BORDE_OBJETIVOS << 1), Video.Alto - (Definiciones.BORDE_OBJETIVOS << 1) - m_hud.Alto, Definiciones.ALPHA_OBJETIVOS, Superficie.V_CENTRO | Superficie.H_CENTRO);
            if (m_paginaActual == 0)
            {
                g.SetearFuente(AdministradorDeRecursos.Instancia.Fuentes[Definiciones.FUENTE_TITULO_OBJETIVOS], Definiciones.GUI_COLOR_TEXTO);
            }
            else
            {
                g.SetearFuente(AdministradorDeRecursos.Instancia.Fuentes[Definiciones.FUENTE_OBJETIVOS], Definiciones.GUI_COLOR_TEXTO);
            }

            g.Escribir(Res.STR_PRIMER_BATALLA + m_paginaActual + (m_nivelActual.NroBatallaActual * Definiciones.PAGINAS_POR_INTRO), 0, -(m_hud.Alto >> 1), Superficie.V_CENTRO | Superficie.H_CENTRO);

            m_boton.Dibujar(g);
        }
    }
}
