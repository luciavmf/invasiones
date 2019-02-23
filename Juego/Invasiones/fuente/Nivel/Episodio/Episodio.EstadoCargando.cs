using System;
using System.Collections.Generic;
using System.Text;
using Invasiones.Dibujo;
using Invasiones.Recursos;
using Invasiones.Map;
using Invasiones.GUI;
using Invasiones.Nivel.Jugadores;
using Invasiones.Audio;

namespace Invasiones.Nivel
{
	public partial class Episodio
	{


        private const int CAJA_OBJETIVOS_ANCHO = 600;
        private const int CAJA_OBJETIVOS_ALTO = 270;

        private const int CAJA_OBJETIVOS_OFFSET_BOTON_Y = 70;
		/// <summary>
		/// Actualiza el estado cargadnos
		/// </summary>
		private void ActualizarEstadoCargado()
		{
			//cargo el nivel
			if (CargarNivel(0))
			{
				//Esto es horribl aca, pero para que pinte algo por lo menos..
				ActualizarEstadoJugando();

				SetearNuevoObjetivo();

				Sonido.Instancia.Parar(Res.SFX_SPLASH);
				Sonido.Instancia.Reproducir(Res.SFX_BATALLA, -1);

				SetearEstado(ESTADO.MOSTRAR_INTRODUCCION);
			}
		}


		/// <summary>
		/// Dibuja la barra de loading
		/// </summary>
		/// <param name="g"></param>
		private void DibujarEstadoCargando(Video g)
		{
			g.LlenarRectangulo(0);

			g.SetearColor(Definiciones.COLOR_TITULO);
			g.SetearFuente(AdministradorDeRecursos.Instancia.Fuentes[Definiciones.FUENTE_TITULO], Definiciones.COLOR_TITULO);

			g.Escribir(Res.STR_CARGANDO, 0, Definiciones.CARGANDO_Y, Superficie.H_CENTRO);
		}


		/// <summary>
		/// Cargalos sprites que se van a utilizar en el nivel.
		/// </summary>
		private void CargarSprites()
		{
			AdministradorDeRecursos.Instancia.Sprites[Res.SPR_PATRICIO].Cargar();
			AdministradorDeRecursos.Instancia.Sprites[Res.SPR_INGLES].Cargar();
		}

		/// <summary>
		/// Carga los objetos a pintar: edificios, arboles, etc.
		/// </summary>
		/// <returns></returns>
		private bool CargarObjetosAPintar()
		{
			//Creo el array en donde van a estar las unidades.
			m_objetosAPintar = new Objeto[m_mapa.AltoMapaFisico, m_mapa.AnchoMapaFisico];

			m_obstaculos = new List<Obstaculo>();

			Tileset tileSet = null;

			Obstaculo obs;

			for (int i = 0; i < m_mapa.Alto; i++)
			{
				for (int j = 0; j < m_mapa.Ancho; j++)
				{
					if (m_mapa.CapaObstaculos[i, j] != 0)
					{

						tileSet = m_mapa.ObtenerTileset(m_mapa.CapaObstaculos[i, j]);

						obs = new Obstaculo(m_mapa.CapaObstaculos[i, j] - tileSet.PrimerGid, i * 2, j * 2, ref tileSet);

						m_obstaculos.Add(obs);

						m_objetosAPintar[i * 2, j * 2] = obs;
					}
				}
			}
			return true;
		}


		/// <summary>
		/// Carga el nivel pasado por parámetro.
		/// </summary>
		/// <param name="Id">El identificador del nivel a cargar.</param>
		/// <returns>Si pudo cargar el nivele exitosamente o no.</returns>
		public bool CargarNivel(int nroNivel)
		{
			if (m_cuenta == 0)
			{
				m_nroNivel = nroNivel;

				//creo el hud
				m_hud = new Hud();
				//Creo el mapa con la camara como referencia.
				m_camara = new Camara(0, 0, Video.Alto - m_hud.Alto); 
				m_mapa = new Mapa(m_camara);
			}
			else if (m_cuenta == 1)
			{
				if (!m_mapa.Cargar(Res.MAP_NIVEL1 + m_nroNivel))
				{
					return false;
				}

				

				//Seteo el mapa y la camara en los objetos
				Objeto.Mapa = m_mapa;
				Objeto.Camara = m_camara;

                m_nivelActual = new Nivel();
                m_nivelActual.Cargar(m_nroNivel);

			}
			else if (m_cuenta == 2)
			{
				//Cargo los sprites.
				CargarSprites();

			}
			else if (m_cuenta == 3)
			{
				m_boton = new Boton(Res.STR_SIGUIENTE, null);
                m_botonAceptar = new Boton(Res.STR_ACEPTAR, null);

                AdministradorDeRecursos.Instancia.CargarTipoDeUnidades();
			}
			else if (m_cuenta == 4)
			{
				//Cargo los objetod visibles en el mapa.
				if (!CargarObjetosAPintar())
				{
					return false;
				}
			}
			else if (m_cuenta == 5)
			{
				//creo al jugador y al enemigo con las referencias de la camara, objetos a pitnar, mapa y hud
				m_jugador = new BandoArgentino(m_mapa, m_camara, ref m_objetosAPintar, m_hud);
				m_enemigo = new BandoEnemigo(m_mapa, m_camara, ref m_objetosAPintar, m_hud);
			}
			else if (m_cuenta == 6)
			{
				//cargo las unidades del jugador
				if (!m_jugador.CargarUnidades(m_nroNivel))
				{
					return false;
				}
			}
			else if (m_cuenta == 10)
			{
				//cargo las unidades del enemigo
				if (!m_enemigo.CargarUnidades(m_nroNivel))
				{
					return false;
				}
				return true;
			}

			m_cuenta++;
			return false;
		}

	}
}
