using System;
using System.Collections.Generic;
using System.Text;
using Invasiones.Debug;
using System.Drawing;
using Invasiones.Map.PathFinding;

namespace Invasiones.Nivel.Unidades
{
	public partial class Unidad : Objeto
	{
		/// <summary>
		/// El intervalo entre recuperacion y recuperacion cuando esta
		/// sanando.
		/// </summary>
		private int m_puntosDeRecuperacion;

		/// <summary>
		/// La cantidad de puntos de 
		/// </summary>
		private int m_ticksEntreCadaRecuparacion;

		/// <summary>
		/// Se le da la opcion de sanar a la unidad. Renueva sus puntos de resistencia.
		/// </summary>
		public void Sanar(int x, int y)
		{
			m_orden = new Orden(Orden.TIPO.SANAR, x, y);

			Point p = s_mapa.ObtenerPosicionEnLineaDeVision(x, m_posEnTileFisico.X, y, m_posEnTileFisico.Y);

			if (p.X == -1 || p.Y == -1)
			{
				Log.Instancia.Debug("No se la puede mandar a sanar.");
				return;
			}

			SetearSanar(p.X, p.Y);
		}

		/// <summary>
		/// Le dice a la unidad que se vaya a sanar a la posicion x, y
		/// </summary>
		/// <param name="x"></param>
		/// <param name="y"></param>
		private void SetearSanar(int x, int y)
		{
			SetearEstado(ESTADO.MOVIENDO);
			m_proximoEstado = ESTADO.SANANDO;

			//Calculo los tiles necesarios para llegar a la posicion.
			m_caminoASeguir = PathFinder.Instancia.EncontrarCaminoMasCorto(m_posEnTileFisico.X,
				m_posEnTileFisico.Y, x, y);

			if (m_caminoASeguir == null)
			{
				Log.Instancia.Debug("No se encontro el camino para sanar...");
				SetearEstado(ESTADO.OCIO);
				return;
			}
			//Saco el ultimo porque siempre es el nodo inicio.
			m_caminoASeguir.Pop();
			m_subestado = SUBESTADO.INCREMENTAR_PASO;
		}

		/// <summary>
		/// Actualiza el estado sanando.
		/// </summary>
		private void ActualizarEstadoSanando()
		{
			m_cuenta++;
			if (m_cuenta++ > m_ticksEntreCadaRecuparacion)
			{
				m_cuenta = 0;
				m_salud += m_puntosDeRecuperacion;

				if (m_salud >= m_puntosDeResistencia)
				{
					m_salud = m_puntosDeResistencia;
					SetearEstado((int)ESTADO.OCIO);
				}
			}
		}
	}
}
