using System;
using System.Collections.Generic;
using System.Text;
using Invasiones.GUI;
using Invasiones.Map;
using Invasiones.Nivel.Unidades;
using Invasiones.Dibujo;
using System.Drawing;
using Invasiones.Debug;
using Invasiones.Eventos;
using Invasiones.Sprites;

namespace Invasiones.Nivel.Jugadores
{
	public abstract class Jugador
	{
		#region Declaraciones

		/// <summary>
		/// Me dice si cumplio el objetivo o no.
		/// </summary>
		protected bool m_cumplioObjetivo;

		/// <summary>
		/// Los estados por los que pasan los jugadores
		/// </summary>
		protected enum ESTADO
		{
			INICIO,
			CARGANDO,
			JUEGO
		}

        protected AnimObjeto m_aro;

		/// <summary>
		/// Contiene el bando contrario de la clase..
		/// </summary>
		protected Episodio.BANDO m_bando;

		/// <summary>
		/// Guarda si alguna unidad cumplio la orden o no.
		/// </summary>
		protected bool m_alguienCumplioLaOrden;

		/// <summary>
		/// La referencia al hud necesario para agregar las unidad que es seleccionada.
		/// </summary>
		protected Hud m_hud;

		/// <summary>
		/// Todas las unidades correspondientes al jugador
		/// </summary>
		protected List<Unidad> m_unidades;

		/// <summary>
		/// La referencia a la lista ordenada de objetos a pintar.
		/// </summary>
		protected Objeto[,] m_objetosAPintar;

		/// <summary>
		/// El mapa en donde se estan moviendo las unidades.
		/// </summary>
		protected Mapa m_mapa;

		/// <summary>
		/// Contiene todas las formaciones del jugador. Puede tener 0, 1 o mas de 1.
		/// </summary>
		protected List<Grupo> m_grupos;

		/// <summary>
		/// Es estado del jugador.
		/// </summary>
		protected ESTADO m_estado;

		/// <summary>
		/// La referecia a la cámara.
		/// </summary>
		protected Camara m_camara;

		/// <summary>
		/// Contiene las unidades que son seleccionadas en un frame dado.
		/// </summary>
		protected List<Unidad> m_unidadesSeleccionadas;

		/// <summary>
		/// Lasd uidades que se murieron en el frame actual.
		/// </summary>
		protected List<Unidad> m_unidadesMuertas;

		/// <summary>
		/// Las unidades visibles por una unidad dada.
		/// </summary>
		protected List<Unidad> m_unidadesVisibles;

		/// <summary>
		/// Las unidades con las que es posible que colisione una unidad en un frame dado.
		/// </summary>
		protected List<Unidad> m_unidadesPorColisionar;

		/// <summary>
		/// La unidad que esta siendo seleccionada en un momento dado.
		/// </summary>
		protected Unidad m_unidadSeleccionada;

		/// <summary>
		/// La formación que esta siendo seleccionada en un frame dado.
		/// </summary>
		protected Grupo m_grupoSeleccionado;
		#endregion

		#region Constructores
		/// <summary>
		/// constructor de la clase.
		/// </summary>
		public Jugador(Mapa map, Camara cam, Objeto[,] objAPintar, Hud hud)
		{
			m_mapa = map;
			m_camara = cam;
			m_objetosAPintar = objAPintar;
			m_hud = hud;
		}
		#endregion

		#region Metodos Abstract
		/// <summary>
		/// Acualiza el jugador
		/// </summary>
		public abstract void Actualizar();

		/// <summary>
		/// Carga las unidades del jugador.
		/// </summary>
		/// <returns>true si las pudo cargar correctamente</returns>
		public abstract bool CargarUnidades(int nroNivel);
		#endregion

		#region Metodos Protected
		/// <summary>
		/// Devueve una lista con las unidades  visibles. Tambien actualiza 
		/// la matriz que contiene las posiciones de las unidades visibles.
		/// </summary>
		/// <param name="unidad">La unidad a chequear las unidades que tiene cerca.</param>
		/// <returns>una lista con las uniades, o null si no hay ninguna.</returns>
		protected List<Unidad> ObtenerUnidadesYTilesVisibles
			(Unidad unidad)
		{
			List<Unidad> unidadesVisibles = null;

			int inicioI = unidad.PosicionEnTileFisico.X - Unidad.MAXIMA_VISIBILIDAD;
			int inicioJ = unidad.PosicionEnTileFisico.Y - Unidad.MAXIMA_VISIBILIDAD;

			int finalI = unidad.PosicionEnTileFisico.X + Unidad.MAXIMA_VISIBILIDAD;
			int finalJ = unidad.PosicionEnTileFisico.Y + Unidad.MAXIMA_VISIBILIDAD;

			//Chequeo que no me haya pasado de los límites.
			if (finalI > m_mapa.AltoMapaFisico)
			{
				finalI = m_mapa.AltoMapaFisico;
			}

			if (finalJ > m_mapa.AnchoMapaFisico)
			{
				finalJ = m_mapa.AnchoMapaFisico;
			}

			if (inicioI < 0)
			{
				inicioI = 0;
			}

			if (inicioJ < 0)
			{
				inicioJ = 0;
			}

			Unidad unidad2 = null;
			bool unidadVisibleEnPantalla = unidad.EsVisibleEnPantalla();

			for (int i = inicioI; i < finalI; i++)
			{
				for (int j = inicioJ; j < finalJ; j++)
				{
					//Chequeo las distancias hasta el tile.
					double distancia = unidad.CalcularDistancia(i, j);

					if (distancia <= unidad.Visibilidad)
					{
						if (m_objetosAPintar[i, j] != null && m_objetosAPintar[i, j] is Unidad
							&& m_objetosAPintar[i, j] != unidad)
						{
							unidad2 = (Unidad)m_objetosAPintar[i, j];
							if (unidadesVisibles == null)
							{
								unidadesVisibles = new List<Unidad>();
							}
							unidadesVisibles.Add(unidad2);
						}

						if (unidadVisibleEnPantalla && unidad.Bando == Episodio.BANDO.ARGENTINO)
						{
							m_mapa.CapaTilesVisibles[i, j] = Mapa.TILE_VISIBLE;
						}
					}
				}
			}
			return unidadesVisibles;
		}

		/// <summary>
		/// Devuelve las unidades que se tienen que chequear a ver si hay colisiones.
		/// </summary>
		/// <param name="unidad"></param>
		/// <returns></returns>
		protected List<Unidad> ObtenerUnidadesPorColisionar(Unidad unidad)
		{
			List<Unidad> unidadesCercanas = null;

			int inicioI = unidad.PosicionEnTileFisico.X - Unidad.DISTANCIA_A_CHEQUEAR_COLISION;
			int inicioJ = unidad.PosicionEnTileFisico.Y - Unidad.DISTANCIA_A_CHEQUEAR_COLISION;

			int finalI = unidad.PosicionEnTileFisico.X + Unidad.DISTANCIA_A_CHEQUEAR_COLISION;
			int finalJ = unidad.PosicionEnTileFisico.Y + Unidad.DISTANCIA_A_CHEQUEAR_COLISION;

			//Chequeo que no me haya pasado de los límites.
			if (finalI > m_mapa.AltoMapaFisico)
			{
				finalI = m_mapa.AltoMapaFisico;
			}

			if (finalJ > m_mapa.AnchoMapaFisico)
			{
				finalJ = m_mapa.AnchoMapaFisico;
			}

			if (inicioI < 0)
			{
				inicioI = 0;
			}

			if (inicioJ < 0)
			{
				inicioJ = 0;
			}

			Unidad unidad2 = null;

			for (int i = inicioI; i < finalI; i++)
			{
				for (int j = inicioJ; j < finalJ; j++)
				{
					if (m_objetosAPintar[i, j] != null && m_objetosAPintar[i, j] is Unidad
						&& m_objetosAPintar[i, j] != unidad)
					{
						unidad2 = (Unidad)m_objetosAPintar[i, j];

						//Chequeo las distancias entre las unidades.
						double distancia = unidad2.CalcularDistancia(unidad.PosicionEnTileFisico.X, unidad.PosicionEnTileFisico.Y);

						if (distancia <= Unidad.DISTANCIA_A_CHEQUEAR_COLISION)
						{
							if (unidadesCercanas == null)
							{
								unidadesCercanas = new List<Unidad>();
							}
							unidadesCercanas.Add(unidad2);
						}
					}
				}
			}
			return unidadesCercanas;
		}

		/// <summary>
		/// Elimina las unidades que se murieron.
		/// </summary>
		protected void EliminarUnidadesMuertas()
		{
			if (m_unidadesMuertas == null)
			{
				return;
			}

			//saco las unidades muertas.
			foreach (Unidad unidadMuerta in m_unidadesMuertas)
			{
				m_objetosAPintar[unidadMuerta.PosicionEnTileFisico.X, unidadMuerta.PosicionEnTileFisico.Y] = null;
				m_unidades.Remove(unidadMuerta);
			}
		}


		/// <summary>
		/// Actualiza el estado de  todas las unidades, y les setea las ordenes que tiene que seguir.
		/// </summary>
		protected void ActualizarUnidades()
		{
			m_unidadesMuertas = null;

			bool chequearSeleccion = m_unidadSeleccionada == null && m_grupoSeleccionado == null;

			//Actualizo todas las unidades.
			foreach (Unidad unidad in m_unidades)
			{
				ActualizarYMoverUnidadDelMapaDeObjetos(unidad);

				if (chequearSeleccion)
				{
					//Si la unidad es seleccionada, la agrego a la lista de unidades seleccionadas.
					if (unidad.EsSeleccionada)
					{
						//Actualizo el estado del hud
						
                        if (m_unidadesSeleccionadas.Count < 6)
                        {
                            m_hud.UnidadSeleccionada = unidad;
                            m_unidadesSeleccionadas.Add(unidad);
                        }
                        else {
                            unidad.EsSeleccionada = false;
                        }
					}
				}

				m_unidadesVisibles = ObtenerUnidadesYTilesVisibles(unidad);

				if (unidad.SeEstaMoviendo())
				{
					ChequearColisiones(unidad);
				}


                if (unidad.EstadoActual == Unidad.ESTADO.OCIO || unidad.EstadoActual == Unidad.ESTADO.PATRULLANDO)
                {
                    AtacarUnidadesVisibles(unidad);
                }


				switch (unidad.EstadoActual)
				{
					case Unidad.ESTADO.MUERTO:
						if (m_unidadesMuertas == null)
						{
							m_unidadesMuertas = new List<Unidad>();
						}
						m_unidadesMuertas.Add(unidad);
						break;
				}

				if (unidad.CumplioOrden)
				{
					m_alguienCumplioLaOrden = true;
				}
			}

            

            if (m_orden != null && m_orden.Id == Orden.TIPO.MATAR)
            {
                m_alguienCumplioLaOrden = true;

                int inicioI = m_orden.Punto.X - m_orden.Ancho;
                int finalI = m_orden.Punto.X + m_orden.Ancho;
                int inicioJ = m_orden.Punto.Y - m_orden.Ancho;
                int finalJ = m_orden.Punto.Y + m_orden.Ancho;

                for (int i = inicioI; i < finalI; i++)
                {
                    for (int j = inicioJ; j < finalJ; j++)
                    {
                        if (m_objetosAPintar[i, j] != null && m_objetosAPintar[i, j] is Unidad)
                        {
                            Unidad unidad2 = (Unidad)m_objetosAPintar[i, j];

                            if (unidad2.Bando == Episodio.BANDO.ENEMIGO)
                            {
                                m_alguienCumplioLaOrden = false;
                            }
                        }
                    }
                }
            }
        }
		#endregion

		#region Metodos
		/// <summary>
		/// Se fija en que tile esta la unidad, y la saca de tile en el que esta si se movio.
		/// </summary>
		/// <param name="unidad"></param>
		private void ChequearColisiones(Unidad unidad)
		{
			//Obtengo las unidades que es posible que colisione la unidad.
			if ((m_unidadesPorColisionar = ObtenerUnidadesPorColisionar(unidad)) == null)
			{
				return;
			}

			//Chequeo las colisiones con las unidades cercanas.
			if (m_unidadesPorColisionar != null)
			{

				//Chequeo con las unidades cercanas, a ver si colisiona con alguna.
				foreach (Unidad unidad2 in m_unidadesPorColisionar)
				{
					if (unidad.HayColision(unidad2))
					{
						unidad.EsquivarUnidad(unidad2, m_unidadesVisibles);
					}
				}
			}
		}

		/// <summary>
		/// Actualiza el estado de la unidad.
		/// </summary>
		/// <param name="unidad"></param>
		private void ActualizarYMoverUnidadDelMapaDeObjetos(Unidad unidad)
		{
			//Actualizo la uidad.
			if (unidad.Actualizar())
			{
				//TODO: esto no anda muy bien, a veces desaparecen las unidades.
				//Si la unidad se actualizo, es decir, si actualizo su posicion en el mapa.
				if (m_objetosAPintar[unidad.TileAnterior.X, unidad.TileAnterior.Y] != null)
				{
					if (m_objetosAPintar[unidad.TileAnterior.X, unidad.TileAnterior.Y] == unidad)
					{
						m_objetosAPintar[unidad.TileAnterior.X, unidad.TileAnterior.Y] = null;
					}
					else
					{
						//Log.Instancia.Debug("Soy otra unidad.");
					}
				}
				m_objetosAPintar[unidad.PosicionEnTileFisico.X, unidad.PosicionEnTileFisico.Y] = unidad;
			}
		}

		/// <summary>
		/// Ataca a las unidades visibles, segun el modo en el que se encuentre la unidad.
		/// </summary>
		private void AtacarUnidadesVisibles(Unidad unidad)
		{
			//Obtengo las unidades cercanas a esta unidad.
			if (m_unidadesVisibles == null)
			{
				return;
			}

			foreach (Unidad enemigo in m_unidadesVisibles)
			{
				//Si la unidad vista es un enemigo....
				if (enemigo.Bando != m_bando)
				{
					//Si estoy en modo agresivo, voy y la ataco.
                    //if (unidad.ModoActual == (int)Unidad.MODO.AGRESIVO)
                    //{
						if (!enemigo.EstaMuerto())
						{
							unidad.Atacar(enemigo);
						}
                    //}

					//Si estoy en modo defensivo, la ataco solamente 
					//si la unidad enemiga me esta atacando.
					else
					{
						if (enemigo.EstadoActual == Unidad.ESTADO.ATACANDO)
						{
							unidad.Atacar(enemigo);
						}
					}
				}
			}
		}

		/// <summary>
		/// Posiciona la cantidad  cant de unidades en el mapa
		/// </summary>
		/// <param name="cant">La cantidad de unidades a posicionar.</param>
		/// <param name="x">La posicion en x desde que se toma el punto a poner las unidades</param>
		/// <param name="y">La posicion en y desde que se toma el punto a poner las unidades</param>
		protected List<Unidad> PosicionarUnidades(int tipo, int cant, int x, int y)
		{
			if (cant == 0)
			{
				Log.Instancia.Error("No se puede crear una grupo de cantidad 0.");
				return null;
			}

			Point punto = new Point();
			const int IZQ = 0;
			const int ARR = 1;
			const int DER = 2;
			const int ABJ = 3;

			List<Unidad> grupo = new List<Unidad>();

			const int INCREMENTO_ESPIRAL = 2;
			const int INCREMENTO_UNIDADES = 2;

			int i = x;
			int j = y;
			int inc = INCREMENTO_ESPIRAL;


			//i = -inc;
			i = 0;
			j = 0;

			int dir = ARR;

			int puestos = 0;
			//Recorro el mapa en forma de espiral apra encontrar una posicion cercana...
			while (puestos != cant)
			{
				if (m_mapa.EsPosicionCaminable(x + i, y + j))
				{
					grupo.Add(PonerUnidad(tipo, x + i, y + j));

					puestos++;
				}

				if (dir == ARR)
				{
					i += INCREMENTO_UNIDADES;
					if (i == inc)
					{
						dir = DER;
						continue;
					}
				}

				if (dir == DER)
				{
					j += INCREMENTO_UNIDADES;

					if (j == inc)
					{
						dir = ABJ;

						continue;
					}
				}

				if (dir == IZQ)
				{
					j -= INCREMENTO_UNIDADES;
					if (j == -inc)
					{
						dir = ARR;
						inc += INCREMENTO_ESPIRAL;
						continue;
					}
				}

				if (dir == ABJ)
				{
					i -= INCREMENTO_UNIDADES;
					if (i == -inc)
					{
						dir = IZQ;

						continue;
					}
				}
			}

			punto = new Point(x + i, y + j);
			return grupo;

		}

		/// <summary>
		/// Pone una unidade en el punto x, y
		/// </summary>
		/// <param name="idUnidad">El id de la unidad a setear en el mapa.</param>
		/// <param name="i">La posicion en x en el mapa a poner las unidades.</param>
		/// <param name="j">La posicion en y en el mapa a poner las unidades.</param>
		private Unidad PonerUnidad(int idUnidad, int i, int j)
		{
			if (!m_mapa.EsPosicionCaminable(i, j))
			{
				Log.Instancia.Debug("No se puede posicionar la unidad porque el tile no es caminable.");
				return null;
			}

			Unidad unit = new Unidad(idUnidad);
			unit.PosicionEnTileFisico = new Point(i, j);
			unit.TileAnterior = new Point(i, j);


			unit.InicializarXY();

			//le seteo el bando al que pertenece.
			unit.Bando = m_bando;

			//Agrego las unidades a la lista.
			m_unidades.Add(unit);

			m_objetosAPintar[unit.PosicionEnTileFisico.X, unit.PosicionEnTileFisico.Y] = unit;
			return unit;
		}

		/// <summary>
		/// Me dice si el objetivo fue cumplido
		/// </summary>
		/// <returns></returns>
		public bool CumplioObjetivo()
		{
			return m_cumplioObjetivo;
		}

		/// <summary>
		/// El objetivo a cumplir de la unidad.
		/// </summary>
		protected Objetivo m_objetivo;

		/// <summary>
		/// La proxima orden que tiene que cumplir el jugador.
		/// </summary>
		protected Orden m_orden;

        /// <summary>
        /// El objeto que tiene que tomar para cumplir con el objetivo.
        /// </summary>
        protected Objeto m_objetoATomar;

		/// <summary>
		/// Setea un nuevo objetivo que cumplir.
		/// </summary>
		/// <param name="objetivo"></param>
		public void SetearObjetivo(Objetivo objetivo)
		{
			m_objetivo = objetivo;
			m_cumplioObjetivo = false;

			if (m_objetivo != null)
			{
				m_orden = m_objetivo.ProximaOrden();

                if (m_orden != null)
                {
                    if (m_orden.Id == (int)Orden.TIPO.TOMAR_OBJETO)
                    {
                        m_objetoATomar = new Objeto(m_orden.Imagen, m_orden.Punto.X, m_orden.Punto.Y);
                    }

                    m_aro.SetearPosicion(m_orden.Punto.X, m_orden.Punto.Y);
                }
			}
			else
			{
				m_orden = null;
			}

			foreach (Unidad unit in m_unidades)
			{
				unit.SetearOrdenDeObjetivo(m_orden);
			}
		}

        protected List<AnimObjeto> m_fueguitos;

		/// <summary>
		/// Setea la orden que tiene que cumplir.
		/// </summary>
		public void SetearProximaOrden()
		{
			m_alguienCumplioLaOrden = false;
			m_orden = m_objetivo.ProximaOrden();

			if (m_orden == null)
			{

				m_cumplioObjetivo = true;
			}

            else
            {
                while (m_orden != null && m_orden.Id == Orden.TIPO.TRIGGER)
                {

                    if (m_fueguitos == null)
                    {
                        m_fueguitos = new List<AnimObjeto>();

                    }

                    m_fueguitos.Add(m_orden.Animacion);
                    m_mapa.InvalidarTile(m_orden.Punto.X, m_orden.Punto.Y);

                    AnimObjeto animacionNueva = new AnimObjeto(m_orden.Animacion.Animacion, m_orden.Animacion.PosicionEnTileFisico.X - 5, m_orden.Animacion.PosicionEnTileFisico.Y - 5);
                    m_fueguitos.Add(animacionNueva);
                    m_mapa.InvalidarTile(m_orden.Animacion.PosicionEnTileFisico.X - 5, m_orden.Animacion.PosicionEnTileFisico.Y - 5);

                    animacionNueva = new AnimObjeto(m_orden.Animacion.Animacion, m_orden.Animacion.PosicionEnTileFisico.X - 5, m_orden.Animacion.PosicionEnTileFisico.Y);
                    m_fueguitos.Add(animacionNueva);
                    m_mapa.InvalidarTile(m_orden.Animacion.PosicionEnTileFisico.X - 5, m_orden.Animacion.PosicionEnTileFisico.Y);

                    m_orden = m_objetivo.ProximaOrden();
                    
                    if (m_orden == null)
                    {
                        m_cumplioObjetivo = true;
                    }
                    
                }
                if (m_orden != null)
                {
                    m_aro.SetearPosicion(m_orden.Punto.X, m_orden.Punto.Y);
                }
            }

			foreach (Unidad unit in m_unidades)
			{
				unit.SetearOrdenDeObjetivo(m_orden);
			}
		}

		/// <summary>
		/// Borra las unidades seleccionadas.
		/// </summary>
		protected void BorrarUnidadesSeleccionadas()
		{
			if (m_grupoSeleccionado != null)
			{
				m_grupoSeleccionado.EsSeleccionado = false;
			}
			if (m_unidadSeleccionada != null)
			{
				m_unidadSeleccionada.EsSeleccionada = false;
			}

			m_hud.UnidadSeleccionada = null;

			//Borro la seleccion.
			m_grupoSeleccionado = null;
			m_unidadSeleccionada = null;
		}

		/// <summary>
		/// Devuelve la cantidad de unidades.
		/// </summary>
		public int CantidadDeUnidades
		{
			get
			{
				return m_unidades.Count;
			}
		}

		#endregion
	}
}