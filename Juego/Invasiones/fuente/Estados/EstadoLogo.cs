using System;
using System.Collections.Generic;
using System.Text;
using Invasiones.SM;
using Invasiones.Dibujo;
using Invasiones.Audio;
using Invasiones.Debug;
using Invasiones.Recursos;

namespace Invasiones.Estados
{
    /// <summary>
    /// En esta pantalla se muestra el logo de la empresa, la cantidad de milisegundos
    /// LOGO_TIEMPO luego de haber transcurrido LOGO_INICIO milisegundos.
    /// Inicializa algunas cosas necesarias para poder correr la aplicacin. Muestra el
    /// logo de la empresa.
    /// </summary>
    public class EstadoLogo : Estado
    {
        #region Declaraciones
        /// <summary>
        /// La cantidad de Ticks hasta que aparezca el logo.
        /// </summary>
        private const int LOGO_INICIO_CNT = 20;

        /// <summary>
        /// La cantidad de Ticks hasta que debe aparecer el logo
        /// </summary>
        private const int LOGO_TIEMPO_CNT = 70;

        /// <summary>
        /// Logo de la empresa
        /// </summary>
        private Superficie m_logo;

        /// <summary>
        /// Variable utilizada para setear la transparencia del logo.
        /// </summary>
        private byte m_transparencia;

		/// <summary>
		/// Indica si es la primer vez que el usuario ingreso a la aplicacion, si no tiene
		/// el perfil cargado.
		/// </summary>
		private bool m_primeraVez;

        #endregion

        #region Constructores
        /// <summary>
        /// Constructor.
        /// </summary>
        /// <param name="sm">Mquina de estados padre. Necesaria para poder cambiar de
        /// estados dentro de este estado.</param>
        public EstadoLogo(MaquinaDeEstados stateMachine)
            : base(stateMachine)
        {
			m_cuenta = 0;
        }
        #endregion

        #region Destructor - libera recursos
        /// <summary>
        /// Destructor. Libera todos los recursos utilizados.
        /// </summary>
        ~EstadoLogo()
        {
			
        }

		public void Dispose()
		{
			if (m_logo != null)
			{
				m_logo.Dispose();
				m_logo = null;
			}
			GC.SuppressFinalize(this);
        }
        #endregion

        #region Metodos Override
        /// <summary>
        /// Dibuja el estado.
        /// </summary>
        /// <param name="g">La pantalla en donde se dibujar? el estado.</param>
        /// <param name="g"></param>
        public override void Dibujar(Video g)
        {
            g.LlenarRectangulo(Definiciones.COLOR_NEGRO);

            if (m_cuenta > LOGO_INICIO_CNT && m_cuenta < LOGO_TIEMPO_CNT)
            {
                if (m_transparencia < 255 - 10)
                {
                    m_transparencia += 10;
                }
                g.Dibujar(m_logo, 0, 0, (byte) m_transparencia, Superficie.H_CENTRO | Superficie.V_CENTRO);
            }
        }

        /// <summary>
        /// Actualiza el estado.
        /// </summary>
        public override void Actualizar()
        {

            if (m_cuenta == 0)
            {
                AdministradorDeRecursos.Instancia.CargarPathsRecursos();

                AdministradorDeRecursos.Instancia.LeerInfoSprites();

                AdministradorDeRecursos.Instancia.LeerInfoAnimaciones();
				Sonido.Instancia.Inicializar();

                //cargo todos los sonidos del juego
				Sonido.Instancia.CargarTodosLosSonidos();
                m_logo = AdministradorDeRecursos.Instancia.ObtenerImagenAlpha(Res.IMG_LOGO);
                m_transparencia = 10;

				AdministradorDeRecursos.Instancia.CargarFuentes();
				
				m_primeraVez = CargarPerfil();

            }
            else if (m_cuenta > LOGO_INICIO_CNT + LOGO_TIEMPO_CNT)
            {
                //Estados Creacion de usuario y splash cambiados por Menu Principal
                //if (m_primeraVez)
                //{
                //    m_maquinaDeEstados.SetearElProximoEstado((int)GameFrame.ESTADO.CREACION_DE_USUARIO);
                //}
                //else
                //{
                //    m_maquinaDeEstados.SetearElProximoEstado((int)GameFrame.ESTADO.SPLASH);
                //}
                m_maquinaDeEstados.SetearElProximoEstado(GameFrame.ESTADO.MENU_PRINCIPAL);
            }
            m_cuenta++;
        }

        /// <summary>
        /// Inicializa el estado.
        /// </summary>
		public override void Iniciar()
        {
        }

        /// <summary>
        /// Sale del estado.
        /// </summary>
        public override void Salir()
        {
			if (m_logo != null)
			{
				m_logo.Dispose();
				m_logo = null;
			}
        }
        #endregion

		#region Metodos
		/// <summary>
		/// Carga el último perfil guardado
		/// </summary>
		/// <returns>true si pudo cargar el perfil.
		/// false si no lo pudo cargar o hubo algun error.</returns>
		private bool CargarPerfil()
		{
			//TODO: false hardcodeado. Cargar el perfil
			return false;
		}
		#endregion
    }
}