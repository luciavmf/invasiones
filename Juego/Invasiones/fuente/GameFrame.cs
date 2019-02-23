using System;
using System.Collections.Generic;
using System.Text;
using System.Windows.Forms;
using Tao.Sdl;
using Invasiones.SM;
using Invasiones.Debug;
using Invasiones.Eventos;
using Invasiones.Estados;
using System.Xml;
using Invasiones.Recursos;
using Invasiones;
using Invasiones.Map;
using Invasiones.Dibujo;

namespace Invasiones
{
	/// <summary>
	/// GameFrame. Es la clase que provee la pantalla del juego.
	/// Contiene el loop del juego.
	/// </summary>
	public class GameFrame
	{
		#region Declaraciones

		/// <summary>
		/// Las pantallas del jeugo
		/// </summary>
		public enum ESTADO
		{
            INVALIDO = -2,
			FIN,
			LOGO,
            //SPLASH,
			JUEGO,
			AYUDA,
            //CREACION_DE_USUARIO,
			MENU_PRINCIPAL,
			INTRODUCCION_CONSECUENCIAS,
			CREDITOS,
			OPCIONES,
			SALIR
		}

		/// <summary>
		/// La pantalla donde pintar el juego.
		/// </summary>
		private Video m_pantalla;

		/// <summary>
		/// Los frames por segundo (FPS) actual.
		/// </summary>
		private int m_fps;

		/// <summary>
		/// Los fps actuales.
		/// </summary>
		public static double FPS;

		/// <summary>
		/// Cuanto tiempo tarda un frame en pintar, el período.
		/// </summary>
		private int m_periodo;

		/// <summary>
		/// La máquina de estados que contiene todos los estado.
		/// </summary>
		private MaquinaDeEstados m_maquinaDeEstados;

		private int m_intervaloEntreEstadisticas = 0;
		private int m_prevStatsTime;

		/// <summary>
		/// El tiempo total desde que se comenzó el juego.
		/// </summary>
		private int m_totalElapsedTime = 0;


		/// <summary>
		/// El tiempo total desde que se comenzó el juego.
		/// </summary>
		private int m_timeSpentInGame = 0;

		/// <summary>
		/// Tiempo gastado en el juego, en milisegundos
		/// </summary>
		private int m_frameCount = 0;

		/// <summary>
		/// Utilizado para crear las estadísticas de los fps
		/// </summary>
		private double[] m_fpsStore;

		private int m_statsCount = 0;

		/// <summary>
		/// El fps promedio.
		/// </summary>
		private double m_promedioFPS = 0.0;

		/// <summary>
		/// El número de FPS para sacar las estadísticas
		/// </summary>
		private const int NUM_FPS = 10;

		/// <summary>
		/// El máximo itervalo entre las estadísticas -> 1 segundo
		/// </summary>
		private const long MAX_STATS_INTERVAL = 1L;

		private int m_tiempoAntesDelFrame;

		private int m_tiempoDespuesDelFrame;

		//Me dice si la aplicacion esta en foco o no.
		private bool m_aplicacionEnFoco;
		#endregion

		#region Constructores
		/// <summary>
		/// Crea el marco del juego.
		/// </summary>
		/// <param name="width">El ancho de la pantalla.</param>
		/// <param name="height">El alto de la pantalla.</param>
		/// <param name="fps">El número de fps</param>
		/// <param name="fullscreen">True para fullscreen</param>
		public GameFrame(short width, short height, int fps, bool fullscreen)
		{

			m_fps = fps;
			m_periodo = (int)1000.0 / fps;

			m_fpsStore = new double[NUM_FPS];
			m_upsStore = new double[NUM_FPS];
			for (int i = 0; i < NUM_FPS; i++)
			{
				m_fpsStore[i] = 0.0;
				m_upsStore[i] = 0.0;
			}
			m_pantalla = new Dibujo.Video();

			Texto.Cargar();

			if (m_pantalla.Iniciar(width, height, fullscreen))
			{
				Run();
			}
			else
			{
				//si no se inicializa bien, se sale de la aplicación.
				MessageBox.Show(Sdl.SDL_GetError(), Texto.Strings[Res.STR_FATAL_ERROR_CAPTION]);
			}
		}
		#endregion

		#region Run - Inicio del Juego

		/// <summary>
		/// El momento en que empezó el juego
		/// </summary>
		private int m_gameStartTime;

		private const int MAX_FRAME_SKIPS = 5;

		int m_framesSalteados = 0;
		/// <summary>
		/// Método Run de la aplicación. Aca esta el loop del juego.
		/// </summary>
		public void Run()
		{
			IniciarJuego();

			int beforeTime;
			int afterTime;
			int timeDiff;
			int sleepTime;

			int overSleepTime = 0;
			int excess = 0;

			m_gameStartTime = Sdl.SDL_GetTicks();
			m_prevStatsTime = m_gameStartTime;
			beforeTime = m_gameStartTime;

			while (m_maquinaDeEstados.EstadoActual != ESTADO.FIN)
			{
				long tAntesAct = Sdl.SDL_GetTicks();
				Actualizar();
				long tDespuesAct = Sdl.SDL_GetTicks();


				Dibujar();
				long tDespuesDib = Sdl.SDL_GetTicks();

				long tiempoAct = tDespuesAct- tAntesAct;
				long tiempoDib = tDespuesDib - tDespuesAct;

				//Log.Instancia.Debug("Actuali: " + tiempoAct + ", Dibujado: " + tiempoDib + ", Deseado: " + m_periodo);


				afterTime = Sdl.SDL_GetTicks();
				timeDiff = afterTime - beforeTime;
				sleepTime = (m_periodo - timeDiff) - overSleepTime;

				if (sleepTime > 0)
				{
					// some time left in this cycle
					Sdl.SDL_Delay(sleepTime); // already in ms
					overSleepTime = (int)((Sdl.SDL_GetTicks() - afterTime) - sleepTime);
				}
				else
				{ // sleepTime <= 0; the frame took longer than the period
					excess -= sleepTime; // store excess time value
					overSleepTime = 0;
				}

				beforeTime = Sdl.SDL_GetTicks();

				//If frame animation is taking too long, update the game state
				//without rendering it, to get the updates/sec nearer to the
				//required FPS.

				int skips = 0;
				while ((excess > m_periodo) && (skips < MAX_FRAME_SKIPS))
				{
					excess -= m_periodo;
					Actualizar(); // update state but don't render
					skips++;
				}
				m_framesSalteados += skips;

				GuardarEstadisticas();



			}
			ImprimirEstadisticas();
			LiberarTodosLosRecursos();
		}

		/// <summary>
		/// Inicia la maquina de estados
		/// </summary>
		private void IniciarJuego()
		{
			Mouse.Instancia.PosicionarCursor(Programa.ANCHO_DE_LA_PANTALLA / 2, Programa.ALTO_DE_LA_PANTALLA / 2);
			Mouse.Instancia.OcultarCursor();
			m_aplicacionEnFoco = true;

			m_maquinaDeEstados = new MaquinaDeEstados();
			m_maquinaDeEstados.AgregarEstado(ESTADO.LOGO, new EstadoLogo(m_maquinaDeEstados));
            //m_maquinaDeEstados.AgregarEstado((int)ESTADO.SPLASH, new EstadoSplash(m_maquinaDeEstados));
			m_maquinaDeEstados.AgregarEstado(ESTADO.MENU_PRINCIPAL, new EstadoMenuPpal(m_maquinaDeEstados));
			m_maquinaDeEstados.AgregarEstado(ESTADO.JUEGO, new EstadoJuego(m_maquinaDeEstados));
			m_maquinaDeEstados.AgregarEstado(ESTADO.FIN, null);
            //m_maquinaDeEstados.AgregarEstado( (int ) ESTADO.CREACION_DE_USUARIO, new EstadoCreacionDeUsuario(m_maquinaDeEstados));
			m_maquinaDeEstados.AgregarEstado(ESTADO.AYUDA, new EstadoAyuda(m_maquinaDeEstados));
			m_maquinaDeEstados.AgregarEstado(ESTADO.OPCIONES, new EstadoOpciones(m_maquinaDeEstados));
			//m_maquinaDeEstados.AgregarEstado((int)ESTADO.CREDITOS, new EstadoCreditos(m_maquinaDeEstados));
			//m_maquinaDeEstados.AgregarEstado((int)ESTADO.INTRODUCCION_CONSECUENCIAS, new EstadoIntroduccionConsecuencias(m_maquinaDeEstados));
			m_maquinaDeEstados.SetearEstado(ESTADO.LOGO);
			m_maquinaDeEstados.AgregarEstado(ESTADO.SALIR, new EstadoSalir(m_maquinaDeEstados));
		}

		#endregion


		/// <summary>
		/// Utilizado para crear las estadísticas de los ups
		/// </summary>
		private double[] m_upsStore;

		private double m_promedioUPS = 0.0;

		/// <summary>
		/// Guarda el total de frames salteados
		/// </summary>
		private long m_totalFramesSkipped = 0L;

		/// <summary>
		/// Los updates por segundo actuales
		/// </summary>
		public static double UPS;

		#region Estadisticas
		/// <summary>
		/// Guarda las estadísticas:
		/// the summed periods for all the iterations in this interval ( el periodo es el monto de 
		/// tiemp de que una sola iteracion de un frame deberia tomar), el tiemp total transcurrido
		/// en este intrvalo, el error entre esos dos números;
		/// La cuenta total de frames, que es el número total de llamadas a Run();
		/// Los FPS (frames/seg)  para este intervalo, el promedio de FPS
		/// sobre el último intervalo de NUM_FPSs. La data es colectada cada 
		/// MAX_STATS_INTERVAL (1 ses).
		/// </summary>
		private void GuardarEstadisticas()
		{
			m_frameCount++;
			m_intervaloEntreEstadisticas += m_periodo;
			//guarda las estadísticas cada MAX_STATS_INTERVAL (1 segunodo)
			if (m_intervaloEntreEstadisticas >= MAX_STATS_INTERVAL)
			{

				int timeNow = Sdl.SDL_GetTicks();
				m_timeSpentInGame = (int)((timeNow - m_gameStartTime) / 1000L); // ms --> secs


				int realElapsedTime = timeNow - m_prevStatsTime; // time since last
				// stats collection
				m_totalElapsedTime += realElapsedTime;

				m_totalFramesSkipped += m_framesSalteados;

				double actualFPS = 0; // calculate the latest FPS and UPS
				double actualUPS = 0;
				if (m_totalElapsedTime > 0)
				{
					FPS = actualFPS = (((double)m_frameCount / m_totalElapsedTime) * 1000L);
					UPS = actualUPS = (((double)(m_frameCount + m_totalFramesSkipped) / m_totalElapsedTime) * 1000L);
				}

				// store the latest FPS and UPS
				m_fpsStore[(int)m_statsCount % NUM_FPS] = actualFPS;
				m_upsStore[(int)m_statsCount % NUM_FPS] = actualUPS;
				m_statsCount = m_statsCount + 1;

				double totalFPS = 0.0; // total the stored FPSs and UPSs
				double totalUPS = 0.0;
				for (int i = 0; i < NUM_FPS; i++)
				{
					totalFPS += m_fpsStore[i];
					totalUPS += m_upsStore[i];
				}

				if (m_statsCount < NUM_FPS)
				{
					// obtain the average FPS and UPS
					m_promedioFPS = totalFPS / m_statsCount;
					m_promedioUPS = totalUPS / m_statsCount;
				}
				else
				{
					m_promedioFPS = totalFPS / NUM_FPS;
					m_promedioUPS = totalUPS / NUM_FPS;
				}
				m_framesSalteados = 0;
				m_prevStatsTime = timeNow;
				m_intervaloEntreEstadisticas = 0;
			}
		}

		/// <summary>
		/// Imprime las estadísticas de FPS.
		/// </summary>
		private void ImprimirEstadisticas()
		{
			Log.Instancia.Debug("Average FPS: " + m_promedioFPS);
			Log.Instancia.Debug("Time Spent: " + m_timeSpentInGame + " secs");
		}
		#endregion

		#region Metodos
		/// <summary>
		/// Dibuja el juego
		/// </summary>
		private void Dibujar()
		{
			m_maquinaDeEstados.Dibujar(m_pantalla);
			Mouse.Instancia.DibujarCursor(m_pantalla);
			m_pantalla.Refrescar();
		}

		/// <summary>
		/// Actualiza el juego.
		/// </summary>
		private void Actualizar()
		{
			if (ActualizarEventos())
			{
				SalirDeLaAplicacion();
			}

			if (m_aplicacionEnFoco)
			{
				m_maquinaDeEstados.Actualizar();
			}
		}

        private int m_ultimaTeclaApretada;
		/// <summary>
		/// Actualiza los eventos.
		/// </summary>
		/// <returns>true si hay que salir de la aplicación.</returns>
		private bool ActualizarEventos()
		{
			Sdl.SDL_Event eventoEscuchado = new Sdl.SDL_Event();

            while (Sdl.SDL_PollEvent(out eventoEscuchado) == 1)
            {

                switch (eventoEscuchado.type)
                {
                    //Pulsacion del teclado
                    case Sdl.SDL_KEYDOWN:

                        if (eventoEscuchado.key.keysym.sym != m_ultimaTeclaApretada)
                        {
                            m_ultimaTeclaApretada = eventoEscuchado.key.keysym.sym;
                            Teclado.Instancia.TeclasApretadas.Add(eventoEscuchado.key.keysym.sym);
                        }
                        
                        break;

                    case Sdl.SDL_KEYUP:
                        m_ultimaTeclaApretada = -1;
                        Log.Instancia.Debug("AFUERA TECLAAAAAAAAAAAAAAAAAAA");
                        Teclado.Instancia.TeclasApretadas.Remove(eventoEscuchado.key.keysym.sym);
                        break;

                    //Fin del programa
					case Sdl.SDL_QUIT:
						return true;

					//Movimiento del raton
					case Sdl.SDL_MOUSEMOTION:
						Mouse.Instancia.X = eventoEscuchado.motion.x;
						Mouse.Instancia.Y = eventoEscuchado.motion.y;
						break;

					case Sdl.SDL_MOUSEBUTTONDOWN:
						Mouse.Instancia.BotonesApretados.Add(eventoEscuchado.button.button);
						break;

					case Sdl.SDL_MOUSEBUTTONUP:
						Mouse.Instancia.BotonesApretados.Remove(eventoEscuchado.button.button);
						break;

					case Sdl.SDL_ACTIVEEVENT:
						if (eventoEscuchado.active.gain == 0)
						{
							PausarAplicacion();
						}
						else
						{
							ReanudarAplicacion();
						}
						break;
				}

			}

			Mouse.Instancia.Actualizar();

			return false;
		}

		/// <summary>
		/// Reanuda la aplicacion cuando el mouse entra a la pantalla.
		/// </summary>
		private void ReanudarAplicacion()
		{
			m_aplicacionEnFoco = true;
			m_tiempoAntesDelFrame = Sdl.SDL_GetTicks();
			m_tiempoDespuesDelFrame = Sdl.SDL_GetTicks();
		}

		/// <summary>
		/// Pausa la aplicacion cuando el mouse sale de la pantalla.
		/// </summary>
		private void PausarAplicacion()
		{
			m_aplicacionEnFoco = false;
		}

		/// <summary>
		/// Sale de el juego. Libera los recursos.
		/// </summary>
		private void SalirDeLaAplicacion()
		{
			LiberarTodosLosRecursos();
			System.Environment.Exit(1);
		}

		/// <summary>
		/// Libera los recursos tomados: libera la pantalla j libera la máquina de estados
		/// </summary>
		private void LiberarTodosLosRecursos()
		{
			m_maquinaDeEstados.Dispose();
			m_maquinaDeEstados = null;
			AdministradorDeRecursos.Instancia.Dispose();
			m_pantalla.Dispose();
			m_pantalla = null;
			Log.Instancia.Dispose();
		}
		#endregion
	}
}