using System;
using System.Collections.Generic;
using System.Text;
using Invasiones.Map;
using Invasiones.Dibujo;
using System.Drawing;
using Invasiones.Debug;

namespace Invasiones.Nivel
{
	/// <summary>
	/// Contiene los Objetos del mapa a ser dibujados. (edificios, arboles, rocas, etc.)
	/// </summary>
	public class Objeto
	{

		#region Atributos

		/// <summary>
		/// La imagen correspondienre al objeto.
		/// </summary>
		protected Superficie m_imagen;

		/// <summary>
		/// La camara
		/// </summary>
		protected static Camara s_camara;

		/// <summary>
		/// El mapa
		/// </summary>
		protected static Mapa s_mapa;

		/// <summary>
		/// La posición en el mapa en la que se encuentra la unidad.
		/// </summary>
		protected Point m_posEnMundoPlano;

		/// <summary>
		/// La posición del tile transformado en el que se encuentra la unidad.
		/// </summary>
		protected Point m_posEnTileFisico;

		/// <summary>
		/// La posición del tile transformado en el que se encuentra la unidad.
		/// </summary>
		protected Point m_posEnTileAnterior;

		/// <summary>
		/// El ancho del frame de la imagen
		/// </summary>
		protected int m_frameAncho;

		/// <summary>
		/// El alto del frame de la imagen.
		/// </summary>
		protected int m_frameAlto;

		/// <summary>
		/// La posicion en pantalla en donde va a ser dibujada la unidad.
		/// </summary>
		protected int m_x;

		/// <summary>
		/// La posicion en pantalla en donde va a ser dibujada la unidad.
		/// </summary>
		protected int m_y;

		#endregion

		#region Propiedades
		/// <summary>
		/// La posición del sprite en el mapa.
		/// </summary>
		public Point TileAnterior
		{
			get
			{
				return m_posEnTileAnterior;
			}
			set
			{
				m_posEnTileAnterior = value;
			}
		}

		/// <summary>
		/// La posición del sprite en el mapa.
		/// </summary>
		public Point PosicionEnTileFisico
		{
			get
			{
				return m_posEnTileFisico;
			}
			set
			{
				m_posEnTileFisico = value;
			}
		}

		/// <summary>
		/// La posiciones en el mundo plano
		/// </summary>
		public Point PosEnMundoPlano
		{
			get
			{
				return m_posEnMundoPlano;
			}
		}

		/// <summary>
		/// La camara
		/// </summary>
		public static Camara Camara
		{
			get
			{
				return s_camara;
			}
			set
			{
				s_camara = value;
			}
		}

		/// <summary>
		/// El mapa
		/// </summary>
		public static Mapa Mapa
		{
			get
			{
				return s_mapa;
			}
			set
			{
				s_mapa = value;
			}
		}

		#endregion


		/// <summary>
		/// Constructor
		/// </summary>
		/// <param name="i">El tile i en donde se encuentra el objeto. </param>
		/// <param name="j">El tile j en donde se encuentra el objeto. </param>
		public Objeto(Superficie sup, int i, int j)
		{
			m_imagen = sup;

			if (m_imagen != null)
			{
				m_frameAlto = sup.Alto;
				m_frameAncho = sup.Ancho;
			}

			m_posEnTileFisico.X = i;
			m_posEnTileFisico.Y = j;


			Point p = TransformarIJEnXY(m_posEnTileFisico.X, m_posEnTileFisico.Y);

			m_posEnMundoPlano.X = p.X;
			m_posEnMundoPlano.Y = p.Y;
		}

		/// <summary>
		/// Constructor de la clase.
		/// </summary>
		public Objeto()
		{

		}

		public virtual void Actualizar()
		{
			ActualizarPosicionXY();
		}

		/// <summary>
		/// Actualiza la posición m_x y  m_y, que son las posiciones en 
		/// donde se va a pintar la unidad en pantalla.
		/// </summary>
		protected virtual void ActualizarPosicionXY()
		{
			m_x = s_camara.InicioX + m_posEnMundoPlano.X + s_camara.X;
			m_y = s_camara.InicioY + m_posEnMundoPlano.Y + s_camara.Y;
		}

		/// <summary>
		/// Dibuja el objeto en la posición  propia.
		/// </summary>
		/// <param name="g"></param>
		public virtual void Dibujar(Video g) 
		{
			if (m_imagen != null)
			{
				g.Dibujar(m_imagen, m_x - m_frameAncho / 2 + s_mapa.TileAncho / 2, m_y - m_frameAlto + s_mapa.TileAlto / 4, 0);
			}
		}

		/// <summary>
		/// Transforma un tile del mapa en una posicion x, y en donde pintar a la unidad.
		/// </summary>
		/// <param name="i">La posicion del tile en i.</param>
		/// <param name="j">La posicion del tile en j.</param>
		/// <returns>El punto en del mapa en x, y.</returns>
		protected virtual Point TransformarIJEnXY(int i, int j)
		{
			Point p = new Point();

			p.X = (((i - j) * s_mapa.TileAncho / 2) >> 1);
			p.Y = (((i + j) * s_mapa.TileAlto / 2) >> 1);

			return p;
		}

		/// <summary>
		/// Setea la posicion del objeto en el tile dado.
		/// </summary>
		/// <param name="x"></param>
		/// <param name="y"></param>
		public void SetearPosicionEnTile(int i, int j)
		{
			m_posEnTileFisico.X = i;
			m_posEnTileFisico.Y = j;


			Point p = TransformarIJEnXY(m_posEnTileFisico.X, m_posEnTileFisico.Y);

			m_posEnMundoPlano.X = p.X;
			m_posEnMundoPlano.Y = p.Y;
			ActualizarPosicionXY();
		}
	}
}
