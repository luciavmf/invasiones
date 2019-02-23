using System;
using System.Collections.Generic;
using System.Text;
using Invasiones.Recursos;
using Invasiones.Map.PathFinding;

namespace Invasiones.Nivel.Unidades
{
	public partial class Unidad : Objeto
	{
		/// <summary>
		/// Hace que la unidad se mueva
		/// </summary>
		/// <param name="x">la posicion del tile chico x hacia donde se movera.</param>
		/// <param name="y">la posicion del tile chico y a donde se movera</param>
		public void Mover(int x, int y)
		{
			m_orden = new Orden(Orden.TIPO.MOVER, x, y);
			
            //m_posicionObjetivo = new Point(x, y);
			//Seteo los proximos estados.

			SetearEstado(ESTADO.MOVIENDO);
			m_proximoEstado = (int)ESTADO.OCIO;

			//Calculo los tiles necesarios para llegar a la posicion.
			m_caminoASeguir = PathFinder.Instancia.EncontrarCaminoMasCorto(m_posEnTileFisico.X,
				m_posEnTileFisico.Y, x, y);

			if (m_caminoASeguir == null)
			{
				SetearEstado(ESTADO.OCIO);
				return;
			}

			//Saco el ultimo porque siempre es el nodo inicio.
			m_caminoASeguir.Pop();

			m_subestado = (int)SUBESTADO.INCREMENTAR_PASO;
		}

		/// <summary>
		/// Actualiza la unidad cuando se le dio la orden de mover.
		/// </summary>
		private bool ActualizarEstadoMoviendo()
		{
			return Moverse();
		}

		/// <summary>
		/// Mueve a la unidad
		/// </summary>
		/// <returns></returns>
		private bool Moverse()
		{

			if (m_orden != null && m_orden.Id == Orden.TIPO.SANAR)
			{ 

			
			}

			switch (m_subestado)
			{
				case SUBESTADO.INCREMENTAR_PASO:
					{
						//Si no hay mas camino a seguir y alcance la ultima posicion:
						if (m_caminoASeguir.Count == 0)
						{
							//Llego al camino, no hay mas nada que popear.
							SetearEstado(m_proximoEstado);
							m_caminoASeguir = null;
							return false;
						}

						m_proximoTile = m_caminoASeguir.Pop();

						m_proximoPaso = TransformarIJEnXY(m_proximoTile.X, m_proximoTile.Y);

						m_subestado = SUBESTADO.ALCANZAR_PASO;
					}
					break;

				case SUBESTADO.ESQUIVAR_UNIDAD:
					{
						RecalcularProximoPaso();
						m_subestado = SUBESTADO.ALCANZAR_PASO;
					}
					return true;
			}

			//Borro los incrementos anteriores
			//m_direccion = -1; BUG FIX
			m_velocidadActual.X = m_velocidadActual.Y = 0;

			//Obtengo la direccion a la que se quiere ir
			int dir = ObtenerDireccion(m_proximoPaso.X, m_proximoPaso.Y);
			m_direccion = dir != -1 ? dir : m_direccion;

			bool llego = false;

			//Me fijo si llegue a la posicion que debo llegar.
			switch (m_direccion)
			{
				case (int)Definiciones.DIRECCION.NE:

					m_velocidadActual.Y = -m_velocidadPorDefecto.Y;
					m_velocidadActual.X = m_velocidadPorDefecto.X;

					if (m_posEnMundoPlano.Y + m_velocidadActual.Y <= m_proximoPaso.Y
						&& m_posEnMundoPlano.X + m_velocidadActual.X >= m_proximoPaso.X)
					{
						llego = true;
					}
					break;

				case (int)Definiciones.DIRECCION.NO:

					m_velocidadActual.Y = -m_velocidadPorDefecto.Y;
					m_velocidadActual.X = -m_velocidadPorDefecto.X;

					if (m_proximoPaso.Y >= m_posEnMundoPlano.Y + m_velocidadActual.Y
						&& m_proximoPaso.X >= m_posEnMundoPlano.X + m_velocidadActual.X)
					{
						llego = true;
					}
					break;

				case (int)Definiciones.DIRECCION.SO:

					m_velocidadActual.Y = m_velocidadPorDefecto.Y;
					m_velocidadActual.X = -m_velocidadPorDefecto.X;

					if (m_proximoPaso.Y <= m_posEnMundoPlano.Y + m_velocidadActual.Y &&
						m_proximoPaso.X >= m_posEnMundoPlano.X + m_velocidadActual.X)
					{
						llego = true;
					}
					break;

				case (int)Definiciones.DIRECCION.SE:

					m_velocidadActual.Y = m_velocidadPorDefecto.Y;
					m_velocidadActual.X = m_velocidadPorDefecto.X;

					if (m_proximoPaso.Y <= m_posEnMundoPlano.Y + m_velocidadActual.Y &&
						m_proximoPaso.X <= m_posEnMundoPlano.X + m_velocidadActual.X)
					{
						llego = true;
					}
					break;

				case (int)Definiciones.DIRECCION.S:

					m_velocidadActual.Y = m_velocidadPorDefecto.Y;

					if (m_posEnMundoPlano.Y + m_velocidadActual.Y >= m_proximoPaso.Y)
					{
						llego = true;
					}
					break;

				case (int)Definiciones.DIRECCION.N:

					m_velocidadActual.Y = -m_velocidadPorDefecto.Y;

					if (m_posEnMundoPlano.Y + m_velocidadActual.Y <= m_proximoPaso.Y)
					{
						llego = true;
					}
					break;

				case (int)Definiciones.DIRECCION.E:

					m_velocidadActual.X = m_velocidadPorDefecto.X;

					if (m_posEnMundoPlano.X + m_velocidadActual.X >= m_proximoPaso.X)
					{
						llego = true;
					}
					break;

				case (int)Definiciones.DIRECCION.O:

					m_velocidadActual.X = -m_velocidadPorDefecto.X;

					if (m_posEnMundoPlano.X + m_velocidadActual.X <= m_proximoPaso.X)
					{
						llego = true;
					}
					break;
				case -1:
					llego = true;
					break;
			}

			if (llego)
			{
				//m_tileAnterior.
				m_posEnTileAnterior.X = m_posEnTileFisico.X;
				m_posEnTileAnterior.Y = m_posEnTileFisico.Y;

				m_posEnTileFisico.Y = m_proximoTile.Y;
				m_posEnTileFisico.X = m_proximoTile.X;

				m_subestado = (int)SUBESTADO.INCREMENTAR_PASO;
			}

			if (m_velocidadActual.X != 0 || m_velocidadActual.Y != 0)
			{
				m_sprite.Reproducir();
				m_sprite.SetearAnimacion(m_direccion + m_primerSprite);
				m_posEnMundoPlano.X += m_velocidadActual.X;
				m_posEnMundoPlano.Y += m_velocidadActual.Y;
			}
			else
			{
				m_sprite.Parar();
			}

			return m_velocidadActual.X != 0 || m_velocidadActual.Y != 0;
		}
		/// <summary>
		/// Setea el subestado de la unidad actual a "SUBESTADO_ESQUIVAR_UNIDAD"
		/// </summary>
		/// <param name="x"></param>
		/// <param name="y"></param>
		public void EsquivarUnidad(Unidad unidad, List<Unidad> unidadesCercanas)
		{
			m_subestado = SUBESTADO.ESQUIVAR_UNIDAD;
			m_unidadAEsquivar = unidad;


			foreach (Unidad unidad2 in unidadesCercanas)
			{
				if (unidad2 != null)
				{
					if (unidad2.SeEstaMoviendo())
					{
						if (unidad2.m_proximoTile != null)
						{
							s_mapa.CapaTilesFisicos[unidad2.m_proximoTile.X, unidad2.m_proximoTile.Y] = Res.TLS_UNIDADES;
						}
					}
					else
					{
						s_mapa.CapaTilesFisicos[unidad2.m_posEnTileFisico.X, unidad2.m_posEnTileFisico.Y] = Res.TLS_UNIDADES;
					}
				}
			}

			Moverse();

			foreach (Unidad unidad2 in unidadesCercanas)
			{
				if (unidad2 != null)
				{


					if (unidad2.SeEstaMoviendo())
					{
						if (unidad2.m_proximoTile != null)
						{
							s_mapa.CapaTilesFisicos[unidad2.m_proximoTile.X, unidad2.m_proximoTile.Y] = Res.TLS_PASTO;
						}
					}
					else
					{
						s_mapa.CapaTilesFisicos[unidad2.m_posEnTileFisico.X, unidad2.m_posEnTileFisico.Y] = Res.TLS_PASTO;
					}
				}
			}
		}


		/// <summary>
		/// Me dice si la unidad esta cerca de la posicion a la que tenia que llegar.
		/// </summary>
		/// <returns></returns>
		public bool CumplioOrdenMover()
		{
			if (m_orden == null)
			{
				return false;
			}
			
			if (Math.Abs(m_orden.Punto.X - m_posEnTileFisico.X) < CANTIDAD_MINIMA_DE_TILES_ORD_MOVER &&
				Math.Abs(m_orden.Punto.Y - m_posEnTileFisico.Y) < CANTIDAD_MINIMA_DE_TILES_ORD_MOVER)
			{
				return true;
			}

			return false;
		}

		/// <summary>
		/// Me dice si la unidad esta cerca de la posicion a la que tenia que llegar.
		/// </summary>
		/// <returns></returns>
		public bool CumplioOrdenSanar()
		{
			if (m_orden == null)
			{
				return false;
			}

			if (m_salud == m_puntosDeResistencia)
			{
				return true;
			}

			return false;
		}

		/// <summary>
		/// Me dice si la unidad esta cerca de la posicion a la que tenia que llegar, de la orden Objetivo.
		/// </summary>
		/// <returns></returns>
		public bool CumplioOrdenObjetivoMover()
		{
			if (m_ordenDeObjetivo == null)
			{
				return false;
			}
			
			if (Math.Abs(m_ordenDeObjetivo.Punto.X - m_posEnTileFisico.X) < CANTIDAD_MINIMA_DE_TILES_ORD_MOVER &&
				Math.Abs(m_ordenDeObjetivo.Punto.Y - m_posEnTileFisico.Y) < CANTIDAD_MINIMA_DE_TILES_ORD_MOVER)
			{
				return true;
			}

			return false;
		}

		
	}
}
