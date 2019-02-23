using System;
using System.Collections.Generic;
using System.Text;
using Invasiones.SM;
using Invasiones.Dibujo;
using Invasiones.GUI;
using Invasiones.Recursos;

namespace Invasiones.Estados
{
	class EstadoSalir : Estado
	{
		/// <summary>
		/// El menu de confirmacion..
		/// </summary>
		private MenuDeConfirmacion m_menuDeConfirmacion;

		public EstadoSalir(MaquinaDeEstados maq)
			: base(maq)
		{ 

		}

		/// <summary>
		/// Inicializa el  menu de confirmacion.
		/// </summary>
		/// <returns></returns>
		public override void Iniciar()
		{
			m_fondo = AdministradorDeRecursos.Instancia.ObtenerImagen(Res.IMG_SPLASH);
			m_menuDeConfirmacion = new MenuDeConfirmacion(Res.STR_CONFIRMACION_SALIR, Res.STR_NO, Res.STR_SI);
			m_menuDeConfirmacion.SetearPosicion(0, 0, Superficie.V_CENTRO | Superficie.H_CENTRO);
		}

		/// <summary>
		/// Dibujo la confirmacion
		/// </summary>
		/// <param name="g"></param>
		public override void Dibujar(Video g)
		{
			g.Dibujar(m_fondo, 0, 0, 0);
			m_menuDeConfirmacion.Dibujar(g);
		}

		/// <summary>
		/// Actualiza el menu.
		/// </summary>
		public override void Actualizar()
		{
			int actualizo = m_menuDeConfirmacion.Actualizar();

			if (actualizo == (int)MenuDeConfirmacion.SELECCION.DERECHO)
			{
				m_maquinaDeEstados.SetearEstado(GameFrame.ESTADO.FIN);
			}

			if (actualizo == (int)MenuDeConfirmacion.SELECCION.IZQUIERDO)
			{
				m_maquinaDeEstados.SetearElProximoEstado(GameFrame.ESTADO.MENU_PRINCIPAL);
			}
		}

		/// <summary>
		/// Sale del menu principal.
		/// </summary>
		/// <returns></returns>
		public override void Salir()
		{
			m_menuDeConfirmacion = null;	
		}
	}
}
