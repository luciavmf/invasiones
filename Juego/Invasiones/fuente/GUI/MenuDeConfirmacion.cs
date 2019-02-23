using System;
using System.Collections.Generic;
using System.Text;
using Invasiones.Recursos;
using Invasiones.Dibujo;

namespace Invasiones.GUI
{
	class MenuDeConfirmacion : CajaGUI
	{
		/// <summary>
		/// Boton izquierdo
		/// </summary>
		private Boton m_botonIzq;

		/// <summary>
		/// Boton derecho
		/// </summary>
		private Boton m_botonDer;


		/// <summary>
		/// Las posibles selecciones dentro del menu.
		/// </summary>
		public enum SELECCION
		{ 
			NINGUNO = -1,
			IZQUIERDO,
			DERECHO
		}

		/// <summary>
		/// Costructor.
		/// </summary>
		/// <param name="leyenda">EL título que va a tener el menú de confirmación.</param>
		/// <param name="boton1">El título del boton izquierdo.</param>
		/// <param name="boton2">El título del boton derecho.</param>
		public MenuDeConfirmacion(int leyenda, int boton1, int boton2)
		{
			m_leyenda = leyenda;
			m_botonIzq = new Boton(boton1, null);
			m_botonIzq.SetearPosicion(0, 0, 0);
			m_botonDer = new Boton(boton2, null);
			m_botonDer.SetearPosicion(200, 200, 0);
			m_ancho = Definiciones.CONFIRMACION_ANCHO;
			m_alto = Definiciones.CONFIRMACION_ALTO;
		}


		/// <summary>
		/// Setea la posicion en donde se va a pintar el menú.
		/// </summary>
		/// <param name="x">Posición x.</param>
		/// <param name="y">Posición y.</param>
		/// <param name="ancla">El ancla de donde tomar el x, y</param>
		public override void SetearPosicion(int x, int y, int ancla)
		{
			m_x = x;
			m_y = y;
			if ((ancla & Superficie.H_CENTRO) != 0)
			{ 
				m_x += (Video.Ancho >> 1) -  (m_ancho>>1);
			}

			if ((ancla & Superficie.V_CENTRO) != 0)
			{
				m_y += (Video.Alto >> 1) - (m_alto >> 1);
			}

			m_botonIzq.SetearPosicion(m_x + Boton.OFFSET_LIMITE_PANTALLA, m_y + m_alto - m_botonIzq.Alto - Boton.OFFSET_LIMITE_PANTALLA, 0);
			m_botonDer.SetearPosicion(m_x  + m_ancho  - m_botonDer.Ancho - Boton.OFFSET_LIMITE_PANTALLA, m_y + m_alto - m_botonDer.Alto - Boton.OFFSET_LIMITE_PANTALLA, 0);

			

			//m_botonIzq.SetearPosicion(
		}


		/// <summary>
		/// Dibuja el boton.
		/// </summary>
		/// <param name="g">El Video en donde pintar.</param>
		public override void Dibujar(Video g)
		{
			g.SetearColor(Definiciones.GUI_COLOR_MENUS);
			g.LlenarRectangulo(m_x, m_y, m_ancho, m_alto, Definiciones.CONFIRMACION_ALPHA, 0);

			g.SetearFuente(AdministradorDeRecursos.Instancia.Fuentes[Definiciones.FUENTE_MENU], Definiciones.GUI_COLOR_TEXTO);

			g.Escribir(m_leyenda, m_x - (Video.Ancho >> 1) + (m_ancho >> 1), m_y + m_alto / 5, Superficie.H_CENTRO);

			m_botonIzq.Dibujar(g);
			m_botonDer.Dibujar(g);
		}

		/// <summary>
		/// Actualiza el menú.
		/// </summary>
		/// <returns>SELECCION.IZQUIERDO si se apreto el botón izquierdo, 
		/// SELECCION.DERECHO si se apreto el botón derecho, 
		/// SELECCION.NINGUNO si no se apreto ningun botón. </returns>
		public override int Actualizar()
		{
			if (m_botonIzq.Actualizar() != 0)
			{
				return (int)SELECCION.IZQUIERDO;
			}

			if (m_botonDer.Actualizar() != 0)
			{
				return (int)SELECCION.DERECHO;
			}

			return (int) SELECCION.NINGUNO;
		}
	}
}
