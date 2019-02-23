using System;
using System.Collections.Generic;
using System.Text;
using Invasiones.SM;
using Invasiones.Sprites;
using Tao.Sdl;
using Invasiones.Debug;
using Invasiones.Dibujo;
using Invasiones.Eventos;
using System.Xml;
using System.Collections;
using System.IO;
using Invasiones.Map;
using Invasiones.Audio;
using Invasiones.Nivel;
using Invasiones.Recursos;
using Invasiones.GUI;

namespace Invasiones.Estados
{
	/// <summary>
	/// GameState. Es el estado donde todo lo referente al juego ocurre.
    /// Dibuja las pantallas, contiene una batalla que es donde ocurre la accion.
    /// Esta clase se encarga de controlar si gano, perdio, ingreso al menu,
    /// Dibuja la interfaz (el hud).
    /// Es una especie de controlador de batalla.
	/// </summary>
    public class EstadoJuego : Estado
    {
        #region Declaraciones

		/// <summary>
		/// Los estados por los que pasa el juego.
		/// </summary>
		private enum ESTADO
		{
			INICIO,
			GANO,
			PERDIO,
			MENU,
			JUGANDO,
			CONFIRMACION
		}

		/// <summary>
		/// Los items dentro del menu.
		/// </summary>
		private enum MENU_ITEM
		{ 
            //CONTINUAR,
            //REINICIAR,
            //GUARDAR, 
            //SALIR
            CONTINUAR,
            SALIR
		}
  
        /// <summary>
        /// La batalla.
        /// </summary>
        private Episodio m_batalla;

		/// <summary>
		/// El menu del juego..
		/// </summary>
		private Menu m_menuDelJuego;

		/// <summary>
		/// Menu de confirmacion utilizado antes de salir.
		/// </summary>
		private MenuDeConfirmacion m_menuDeConfirmacion;

        /// <summary>
        /// El estado actual del juego.
        /// </summary>
        private EstadoJuego.ESTADO m_estado;
        #endregion

        #region Constructores
        /// <summary>
        /// Constructor.
        /// </summary>
        /// <param name="sm">Máquina de estados padre. Necesaria para poder cambiar de
        /// estados dentro de este estado.</param>
        public EstadoJuego(MaquinaDeEstados stateMachine) 
            :base (stateMachine)
        {
        }
        #endregion


		public void Dispose()
		{
			if (m_batalla != null)
			{
				m_batalla.Dispose();
			}
			GC.SuppressFinalize(this);
        }

        #region Metodos Override
        /// <summary>
        /// Dibuja el estado.
        /// </summary>
        /// <param name="g">La pantalla en donde se dibujará el estado.</param>
        public override void Dibujar(Video g)
        {
            switch (m_estado)
            {
                case ESTADO.JUGANDO:

                    m_batalla.Dibujar(g);

					if (m_batalla.Estado == Episodio.ESTADO.JUGANDO)
					{
						m_boton.Dibujar(g);
					}

                    break;

				case ESTADO.MENU:

					m_batalla.Dibujar(g);
					m_menuDelJuego.Dibujar(g);

					g.SetearFuente(AdministradorDeRecursos.Instancia.Fuentes[Definiciones.FUENTE_TITULO], Definiciones.COLOR_BLANCO);
					g.Escribir(Res.STR_JUEGO_PAUSADO, 0, Definiciones.JUEGO_PAUSADO_Y, Superficie.V_CENTRO | Superficie.H_CENTRO);
					break;


				case ESTADO.CONFIRMACION:

					m_batalla.Dibujar(g);
					m_menuDeConfirmacion.Dibujar(g);
					
					break;
            }
        }

        /// <summary>
        /// Actualiza el estado.
        /// </summary>
        public override void Actualizar()
        {

            switch (m_estado)
            {
                case ESTADO.INICIO:
                    m_batalla = new Episodio();
                    m_batalla.Iniciar();
                    m_estado = ESTADO.JUGANDO;

					Superficie boton = AdministradorDeRecursos.Instancia.ObtenerImagenAlpha(Res.IMG_BOTON);
					Superficie botonSel = AdministradorDeRecursos.Instancia.ObtenerImagenAlpha(Res.IMG_BOTON_SELECCION);
					m_boton = new Boton(Res.STR_BOTON_MENU_DEL_JUEGO, null);
					//m_boton.SetearAlto(Boton.ALTO);
					//m_boton.SetearAncho(Boton.ANCHO);

                    m_boton.SetearPosicion(Video.Ancho - m_boton.Ancho - Boton.OFFSET_LIMITE_PANTALLA, Boton.OFFSET_LIMITE_PANTALLA, 0);

                    m_menuDeConfirmacion = new MenuDeConfirmacion(Res.STR_CONFIRMACION_SALIR, Res.STR_NO, Res.STR_SI);
                    m_menuDeConfirmacion.SetearPosicion(0, 0, Superficie.V_CENTRO | Superficie.H_CENTRO);

                    break;

                case ESTADO.JUGANDO:
                    m_batalla.Actualizar();
					if (m_batalla.Estado == Episodio.ESTADO.JUGANDO)
					{
						//Alcualizo el boton del menu
						if (m_boton.Actualizar() != 0)
						{
							SetearEstado(ESTADO.MENU);
						}
					}

                    if (m_batalla.Estado == Episodio.ESTADO.FIN)
                    {
                        m_maquinaDeEstados.SetearElProximoEstado(GameFrame.ESTADO.MENU_PRINCIPAL);
                    }
					break;

				case ESTADO.MENU:
					int itemSeleccionado = m_menuDelJuego.Actualizar();

					switch (itemSeleccionado)
					{
						case (int)MENU_ITEM.CONTINUAR:
							{
								SetearEstado(ESTADO.JUGANDO);
							}
							break;
						case (int) MENU_ITEM.SALIR:
							{
								SetearEstado(ESTADO.CONFIRMACION);
							}
							break;
					}
					break;

				case ESTADO.CONFIRMACION:

					int resultado = m_menuDeConfirmacion.Actualizar();

					if (resultado == (int)MenuDeConfirmacion.SELECCION.IZQUIERDO)
					{
						SetearEstado(ESTADO.JUGANDO);
					}

					if (resultado == (int)MenuDeConfirmacion.SELECCION.DERECHO)
					{
						m_maquinaDeEstados.SetearElProximoEstado(GameFrame.ESTADO.MENU_PRINCIPAL);
						//m_maquinaDeEstados.SetearEstado(GameFrame.ESTADO.FIN);
					}
					
					break;
            }
        }

		/// <summary>
		/// Setea el estado actual.
		/// </summary>
		/// <param name="estado"></param>
		private void SetearEstado(EstadoJuego.ESTADO estado)
		{
			m_estado = estado;
		}

        /// <summary>
        /// Inicializa el estado.
        /// </summary>
		public override void Iniciar()
        {
            m_estado = (int) ESTADO.INICIO;
			m_menuDelJuego = new Menu(null, 2, 0, 0, Superficie.H_CENTRO | Superficie.V_CENTRO);

			m_menuDelJuego.SetearFuente(AdministradorDeRecursos.Instancia.Fuentes[(int) Definiciones.FUENTE_MENU]);

			m_menuDelJuego.AgregarItem((int)MENU_ITEM.CONTINUAR, Res.STR_MENU_CONTINUAR, Menu.ITEM_VISIBLE);
            //m_menuDelJuego.AgregarItem((int)MENU_ITEM.REINICIAR, Res.STR_MENU_REINICIAR, Menu.ITEM_VISIBLE);
            //m_menuDelJuego.AgregarItem((int)MENU_ITEM.GUARDAR, Res.STR_MENU_GUARDAR, Menu.ITEM_VISIBLE);
			m_menuDelJuego.AgregarItem((int)MENU_ITEM.SALIR, Res.STR_MENU_SALIR, Menu.ITEM_VISIBLE);
        }

        /// <summary>
        /// Sale del estado.
        /// </summary>
		public override void Salir()
        {
        }
        #endregion
    }
}