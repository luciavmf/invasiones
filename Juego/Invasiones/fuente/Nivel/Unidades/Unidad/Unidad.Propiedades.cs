using System;
using System.Collections.Generic;
using System.Text;
using Invasiones.Dibujo;
using System.Drawing;

namespace Invasiones.Nivel.Unidades
{
	public partial class Unidad : Objeto
	{

        ///// <summary>
        ///// Setea el modo de la unidad: defensivo o agresivo.
        ///// </summary>
        //public int ModoActual
        //{
        //    get
        //    {
        //        return m_modo;
        //    }
        //    set
        //    {
        //        m_modo = value;
        //    }
        //}


		/// <summary>
		/// El proximo tile al que se dirige la unidad.
		/// </summary>
		public Point ProximoTile
		{
			get
			{
				return m_proximoTile;
			}
		}

		/// <summary>
		/// La posicion deseada para el flocking
		/// </summary>
		public Point OffsetEnFormacion
		{
			get
			{
				return m_posicionDeseada;
			}
			set
			{
				m_posicionDeseada = value;
			}
		}

		/// <summary>
		/// Devuelve el bando al que pertenece la unidad.
		/// </summary>
		public Episodio.BANDO Bando
		{
			get
			{
				return m_bando;
			}

			set
			{
				if (value != Episodio.BANDO.ENEMIGO && value != Episodio.BANDO.ARGENTINO)
				{
					m_bando = Episodio.BANDO.ENEMIGO;
				}
				else
				{
					m_bando = value;
				}
			}
		}

		/// <summary>
		/// Devuelve el camino a seguir de la unidad.
		/// </summary>
		public Stack<Point> CaminoASeguir
		{
			get
			{
				return m_caminoASeguir;
			}
		}

		/// <summary>
		/// Devuelve la unidad a esquivar.
		/// </summary>
		public Unidad UnidadAEsquivar
		{
			get
			{
				return m_unidadAEsquivar;
			}
		}

		/// <summary>
		/// Estado de la unidad
		/// </summary>
		public Unidad.ESTADO EstadoActual
		{
			get
			{
				return m_estado;
			}
		}

		/// <summary>
		/// Se fija si la unidad fue seleccionada.
		/// </summary>
		public bool EsSeleccionada
		{
			get
			{
				return m_seleccionado;
			}
			set
			{
				m_seleccionado = value;
			}
		}

		/// <summary>
		/// get de los puntos de ataque de la unidad
		/// </summary>
		public int PuntosDeAtaque
		{
			get
			{
				return m_puntosDeAtaque;
			}
		}

		/// <summary>
		/// get de los puntos de resistencia de la unidad
		/// </summary>
		public int Salud
		{
			get
			{
				return m_salud;
			}
		}

		/// <summary>
		/// get de los puntos de resistencia por defecto de la unidad
		/// </summary>
		public int PuntosDeResistencia
		{
			get
			{
				return m_puntosDeResistencia;
			}
		}

		/// <summary>
		/// get del alcance de la unidad
		/// </summary>
		public int Alcance
		{
			get
			{
				return m_alcanceDeTiro;
			}
		}

		/// <summary>
		/// get de la visibilidad de la unidad
		/// </summary>
		public int Visibilidad
		{
			get
			{
				return m_visibilidad;
			}
		}

		/// <summary>
		/// get de la velocidad de la unidad
		/// </summary>
		public Point Velocidad
		{
			get
			{
				return m_velocidadActual;
			}
		}

		/// <summary>
		/// get de la velocidad por defecto de la unidad, la velocidad que se setea en el archico csv
		/// </summary>
		public int VelocidadPorDefecto
		{
			get
			{
				return m_velocidadPorDefecto.X;
			}
		}

		/// <summary>
		/// El intervalo entre ataques
		/// </summary>
		public int IntervaloEntreAtaques
		{
			get
			{
				return m_intervaloEntreAtaques;
			}
		}

		/// <summary>
		/// La punteria de la unidad
		/// </summary>
		public int Punteria
		{
			get
			{
				return m_punteria;
			}
		}

		/// <summary>
		/// La imagen del avatar de la unidad.
		/// </summary>
		public Superficie Avatar
		{
			get
			{
				return m_avatar;
			}
		}

		/// <summary>
		/// El nombre de la unidad.
		/// </summary>
		public string Nombre
		{
			get
			{
				return m_nombre;
			}
		}

		/// <summary>
		/// Me dice si cumplio con la orden o no.
		/// </summary>
		public bool CumplioOrden
		{
			get
			{
				return m_cumplioConLaOrden;
			}
		}
	}
}
