using System;
using System.Collections.Generic;
using System.Collections;
using System.Text;
using Invasiones.Estados;
using Invasiones.Dibujo;
using Invasiones.Debug;

namespace Invasiones.SM
{
	/// <summary>
	/// Máquina de estados. Puedo generar todas las máquinas de etado que crea
	/// conveniente.
	/// </summary>
	public class MaquinaDeEstados
    {
        #region Declaraciones
        /// <summary>
		/// Contiene el estado actual.
		/// </summary>
		private Estado m_estadoActual;

		/// <summary>
		/// Contiene la llave del estado actual.
		/// </summary>
		private GameFrame.ESTADO m_keyEstadoActual;

		/// <summary>
		/// El estado previo.
		/// </summary>
		private Estado m_estadoPrevio;

		/// <summary>
		/// El próximno estado.
		/// </summary>
		private Estado m_proximoEstado;

		/// <summary>
		/// La llave del próximo estado.
		/// </summary>
		private GameFrame.ESTADO m_keyProximoEstado;

		/// <summary>
		/// Hashtable que contiene todos los estados.
		/// </summary>
		private Hashtable m_todosLosEstados;
        #endregion

        #region Properties
        /// <summary>
        /// Devuelve el estado actual.
        /// </summary>
        public GameFrame.ESTADO EstadoActual
        {
            get
            {
                return m_keyEstadoActual;
            }
        }
        #endregion

        #region Constructores
        /// <summary>
		/// Constructor de la clase.
		/// </summary>
		public MaquinaDeEstados()
		{
			m_todosLosEstados = new Hashtable();
        }
        #endregion

        #region Destructor - libero recursos
        /// <summary>
		/// Destructor de la clase. Elimina todos los estados.
		/// </summary>
		~MaquinaDeEstados()
		{
			Dispose();
		}
        
		public virtual void Dispose()
		{
			//foreach (Estado estado in m_todosLosEstados.Values)
			//{
			//    estado.Dispose();
			//}

			m_todosLosEstados.Clear();
			m_todosLosEstados = null;

			GC.SuppressFinalize(this);
        }
        #endregion

        #region Metodos
        /// <summary>
		/// Agrega un estado a la máquina de estados.
		/// </summary>
		/// <param name="key"></param>
		/// <param name="state"></param>
		public void AgregarEstado(GameFrame.ESTADO key, Estado estado)
		{
			m_todosLosEstados.Add(key, estado);
		}

		/// <summary>
		/// Setea el próximo estado.
		/// </summary>
		/// <param name="key"></param>
		public void SetearElProximoEstado(GameFrame.ESTADO key)
		{

			if (m_todosLosEstados.ContainsKey(key))
			{
				m_proximoEstado = (Estado)m_todosLosEstados[key];
				m_keyProximoEstado = key;
			}
			else
			{
				Log.Instancia.Error("La maquina de estados no contiene la clave " + key);
			}
		}

		/// <summary>
		/// Setea el estado dado.
		/// </summary>
		/// <param name="key"></param>
		public void SetearEstado(GameFrame.ESTADO key)
		{
			m_estadoPrevio = m_estadoActual;
			m_estadoActual = (Estado)m_todosLosEstados[key];
			m_keyEstadoActual = key;
		}

		/// <summary>
		/// Actualiza la máquina de estados.
		/// </summary>
		public void Actualizar()
		{
			if (m_proximoEstado != null)
			{
				m_estadoPrevio = m_estadoActual;
				m_estadoActual = m_proximoEstado;
				m_keyEstadoActual = m_keyProximoEstado;

				m_proximoEstado = null;
				m_keyProximoEstado = GameFrame.ESTADO.INVALIDO;
				m_estadoPrevio.Salir();
				m_estadoActual.Iniciar();
			}

			if (m_estadoActual != null)
			{
				m_estadoActual.Actualizar();
			}
		}

		/// <summary>
		/// Debuja el estado actual.
		/// Llama a la función render del estaco actual.
		/// </summary>
		/// <param name="g">The g wher it's going to be drawn</param>
		public void Dibujar(Video gfx)
		{
			if (m_estadoActual != null)
			{
				m_estadoActual.Dibujar(gfx);
			}
        }
        #endregion
	}
}