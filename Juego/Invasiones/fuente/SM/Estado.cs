using System;
using System.Collections.Generic;
using System.Text;
using Invasiones.SM;
using Invasiones.Dibujo;
using Invasiones.GUI;

namespace Invasiones.SM
{
	/// <summary>
	/// Estado. Clase abstracta de donde derivan todos los estados del juego.
	/// </summary>
	public abstract class Estado
    {
        #region Declaraciones
        /// <summary>
		/// Maquina de estados.
		/// </summary>
		protected MaquinaDeEstados m_maquinaDeEstados;

		/// <summary>
		/// El fondo de la pantalla
		/// </summary>
		protected Superficie m_fondo;

		/// <summary>
		/// Boton utilizado para motivos varios.
		/// </summary>
		protected Boton m_boton;

		/// <summary>
		/// Utilizado para cuentas regresivas.
		/// </summary>
		protected long m_cuenta;
        #endregion

        #region Constructores
        /// <summary>
		/// Constructor.
		/// </summary>
		/// <param name="sm">Máquina de estados padre. Necesaria para poder cambiar de
		/// estados dentro de este estado.</param>
		public Estado(MaquinaDeEstados sm)
		{
			m_maquinaDeEstados = sm;
        }
        #endregion

        #region Metodos Abstract
        /// <summary>
		/// Dibuja el estado.
		/// </summary>
		/// <param name="g">La pantalla en donde se dibujará el estado.</param>
		public abstract void Dibujar(Video g);

		/// <summary>
		/// Actualiza el estado.
		/// </summary>
		public abstract void Actualizar();

		/// <summary>
		/// Funcion llamada ada vez que se inicia el estado.
		/// </summary>
		public abstract void Iniciar();

		/// <summary>
		/// Metodo que se llama cada vez que se sale del estado.
		/// </summary>
		public abstract void Salir();
        #endregion
    }
}