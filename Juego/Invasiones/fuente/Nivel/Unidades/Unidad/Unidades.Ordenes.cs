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
		/// Elimina la unidad.
		/// </summary>
		public void Morir()
		{
			Log.Instancia.Debug("Me mori.");
			SetearEstado(ESTADO.MUERTO);
			m_enemigo = null;
		}

		/// <summary>
		/// Avisa a la unidad que esta siendo atacada.
		/// </summary>
		private void ContraAtacar(Unidad enemigo)
		{
            //La unidad contraataca solamente cuando esta en estado ocio.
            if (m_estado != ESTADO.OCIO || m_estado == ESTADO.ATACANDO)
            {
                return;
            }

			Log.Instancia.Debug("Me atacan...");
			m_enemigo = enemigo;

			if (CalcularDistancia(m_enemigo.PosicionEnTileFisico.X, m_enemigo.PosicionEnTileFisico.Y) < m_alcanceDeTiro)
			{
				ApuntarAUnidad(m_enemigo);
				SetearEstado(ESTADO.ATACANDO);
			}
		}

		/// <summary>
		/// Hace que la unidad patrulle.
		/// </summary>
		/// <param name="x"></param>
		/// <param name="y"></param>
		public void Patrullar()
		{
			SetearEstado(ESTADO.PATRULLANDO);
			m_proximoEstado = ESTADO.PATRULLANDO;

			//Seteo la posicion en donde quiero que patrulle..
			m_posicionDePatrulla = new Point(m_posEnTileFisico.X, m_posEnTileFisico.Y);

            m_caminoASeguir = EncontrarCaminoParaPatrullarAlAzar(m_posEnTileFisico.X, m_posEnTileFisico.Y);

		}

		/// <summary>
		/// Hace que la unidad se ataque
		/// </summary>
		/// <param name="enemigo">La unidad que tiene que atacar</param>
		public void Atacar(Unidad enemigo)
		{
			m_enemigo = enemigo;
			m_blanco = new Point(-1, -1);
			SetearEstado(ESTADO.PERSIGUIENDO_UNIDAD);
		}

		/// <summary>
		/// Setea una orden que tiene que cumplir la unidad.
		/// </summary>
		/// <param name="ord">La orden que tiene que chequear si cumplio.</param>
		public void SetearOrdenDeObjetivo(Orden ord)
		{
			m_cumplioConLaOrden = false;
			m_ordenDeObjetivo = ord;
		}

		/// <summary>
		/// Chequea si cumpli el objetivo o no.
		/// </summary>
		private void ChequearSiCumplioOrden()
		{
			if (m_ordenDeObjetivo == null)
			{
				return;
			}

			if (m_ordenDeObjetivo.Id == Orden.TIPO.MOVER || m_ordenDeObjetivo.Id == Orden.TIPO.TOMAR_OBJETO)
			{
				if (CumplioOrdenObjetivoMover())
				{
					m_cumplioConLaOrden = true;
				}
			}
            //if (m_ordenDeObjetivo.Id == Orden.TIPO.MATAR)
            //{ 
                
            //}
		}
	}
}
