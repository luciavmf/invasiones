using System;
using System.Collections.Generic;
using System.Text;
using Invasiones.Dibujo;
using Invasiones.Recursos;
using Invasiones.Eventos;
using Invasiones.Debug;

namespace Invasiones.GUI
{
	public class CuadroDeEntrada : CajaGUI
	{

		/// <summary>
		/// La longitud maxima de caracteres.
		/// </summary>
		private int LONGITUD_PALABRA_MAXIMA = 32;
  
		/// <summary>
		/// EL intervalo en cuenta de frames en el que el j
		/// </summary>
		private const int INTERVALO_ENTRE_CURSOR_TITILA = 20;

		/// <summary>
		/// El texto ingresado.
		/// </summary>
		private string m_textoIngresado;

		/// <summary>
		/// El intervalo entre repeticiones para tomar la tecla.
		/// </summary>
		private int m_cuentaRepeticion;

		/// <summary>
		/// La ultima tecla ingresada.
		/// </summary>
		private char m_ultimaTeclaIngresada;

		/// <summary>
		/// Boton que hay que apretar para seguir ala siguiente pantalla.
		/// </summary>
		private Boton m_botonListo;

		/// <summary>
		/// El largo en pixeles del texto ingresado.
		/// </summary>
		private int m_tamañoTextoIngresado;

		/// <summary>
		/// El itervalo en el que titila el cursor.
		/// </summary>
		private int m_tiempoTitila;

		public CuadroDeEntrada(int leyenda, Superficie img)
		{
			m_leyenda = leyenda;
			m_ancho = Definiciones.CONFIRMACION_ANCHO;
			m_alto = Definiciones.CONFIRMACION_ALTO;
			m_textoIngresado = "";
			m_cuentaRepeticion = 0;

			m_botonListo = new Boton(Res.STR_LISTO, null);

			LONGITUD_PALABRA_MAXIMA = m_ancho - (Boton.OFFSET_LIMITE_PANTALLA << 1) - 20;
		}


		/// <summary>
		/// Actualiza los enventos de entrada y devuelve 1 si
		/// </summary>
		/// <returns></returns>
		public override int Actualizar()
		{

			m_cuentaRepeticion--;

			foreach (int tecla in Teclado.Instancia.TeclasApretadas)
			{
				if (m_ultimaTeclaIngresada != Convert.ToChar(tecla) || m_cuentaRepeticion <=0)
				{
					m_ultimaTeclaIngresada = Convert.ToChar(tecla);

					if (tecla == Teclado.TECLA_BACKSPACE)
					{
						if (m_textoIngresado.Length > 0)
						{
							m_textoIngresado = m_textoIngresado.Remove(m_textoIngresado.Length - 1);
						}
						m_cuentaRepeticion = Teclado.INTERVALO_ENTRE_REPETICIONES / 3;
					}
					else if (tecla == Teclado.TECLA_ENTER)
					{
						if (m_textoIngresado.Length > 0)
						{
							return 1;
						}
					}
					else if (tecla != Teclado.TECLA_RSHIFT && tecla != Teclado.TECLA_LSHIFT) 
					{
						m_cuentaRepeticion = Teclado.INTERVALO_ENTRE_REPETICIONES;

						string caracter = Convert.ToChar(tecla).ToString();

						if (Teclado.Instancia.TeclasApretadas.Contains(Teclado.TECLA_RSHIFT) || Teclado.Instancia.TeclasApretadas.Contains(Teclado.TECLA_LSHIFT))
						{
							caracter = caracter.ToUpper();
						}
						if (m_tamañoTextoIngresado < LONGITUD_PALABRA_MAXIMA)
						{
							m_textoIngresado += caracter;
						}
					}
				}
			}

			if (m_cuentaRepeticion <= 0)
			{
				m_cuentaRepeticion = Teclado.INTERVALO_ENTRE_REPETICIONES;
			}

			if (m_botonListo.Actualizar() != 0)
			{
				return 1;
			}
			return 0;
		}

		/// <summary>
		/// Setea la posicion en donde se va a escribir al cuadro de entrada.
		/// </summary>
		/// <param name="x"></param>
		/// <param name="y"></param>
		/// <param name="ancla"></param>
		public override void SetearPosicion(int x, int y, int ancla)
		{
			m_x = x;
			m_y = y;

			if ((ancla & Superficie.H_CENTRO) != 0)
			{
				m_x += (Video.Ancho >> 1) - (m_ancho >> 1);
			}

			if ((ancla & Superficie.V_CENTRO) != 0)
			{
				m_y += (Video.Alto >> 1) - (m_alto >> 1);
			}

			m_botonListo.SetearPosicion(m_x + m_ancho - m_botonListo.Ancho - Boton.OFFSET_LIMITE_PANTALLA,
				m_y + m_alto - m_botonListo.Alto - Boton.OFFSET_LIMITE_PANTALLA, 0);
		}

		/// <summary>
		/// Dibuja el cuadro de entrada, asi como las teclas que esta apretando el usuario.
		/// </summary>
		/// <param name="g">El video</param>
		public override void Dibujar(Video g)
		{
		
			g.SetearColor (Definiciones.GUI_COLOR_MENUS);
			g.LlenarRectangulo(m_x, m_y, m_ancho, m_alto, Definiciones.GUI_ALPHA, 0);
			g.SetearFuente(AdministradorDeRecursos.Instancia.Fuentes[Definiciones.FUENTE_MENU], Definiciones.GUI_COLOR_TEXTO);
			g.Escribir(m_leyenda, m_x + Boton.OFFSET_LIMITE_PANTALLA, m_y + Boton.OFFSET_LIMITE_PANTALLA, 0);

			g.SetearColor(Definiciones.COLOR_NEGRO);
			g.LlenarRectangulo(m_x + Boton.OFFSET_LIMITE_PANTALLA, m_y - (Video.Alto >> 1) + (m_alto >> 1), m_ancho - (Boton.OFFSET_LIMITE_PANTALLA << 1) , Boton.ALTO, 255, Superficie.V_CENTRO);

			g.SetearFuente(AdministradorDeRecursos.Instancia.Fuentes[Definiciones.FUENTE_MENU], Definiciones.GUI_COLOR_TEXTO);


			m_tamañoTextoIngresado = g.Escribir(m_textoIngresado, m_x + Boton.OFFSET_LIMITE_PANTALLA + 5, m_y - (Video.Alto >> 1) + (m_alto >> 1), Superficie.V_CENTRO);

			

			if (m_tiempoTitila-- < 0)
			{
				g.Escribir("|", m_x + Boton.OFFSET_LIMITE_PANTALLA + 5 + m_tamañoTextoIngresado, m_y - (Video.Alto >> 1) + (m_alto >> 1) - 2, Superficie.V_CENTRO);
				if ( m_tiempoTitila < -INTERVALO_ENTRE_CURSOR_TITILA)
				{
					m_tiempoTitila = INTERVALO_ENTRE_CURSOR_TITILA;
				}
			}

			m_botonListo.Dibujar(g);
			
		}
	}
}
