using System;
using System.Collections.Generic;
using System.Text;
using System.Xml;
using System.IO;
using Invasiones.Debug;
using Invasiones.Dibujo;
using System.Collections;
using Invasiones.Recursos;
using System.Drawing;

namespace Invasiones.Map
{
	/// <summary>
	/// Representa a un tileset contenido por el Mapa
	/// </summary>
	public class Tileset
    {
        #region Declaraciones
        /// <summary>
		/// El primer Id del tileset, Se supoe que un m_mapa puede tener mas de un tileset, entonces
		/// esto sirve para saber a qué tileset pertenece una posición en el m_mapa.
		/// </summary>
		public short PrimerGid;

		/// <summary>
		/// El nombre de tileset 
		/// </summary>
		private string m_nombre;

		/// <summary>
		/// El id del tileset 
		/// </summary>
		private short m_id;

		/// <summary>
		/// El ancho de cada tile
		/// </summary>
		private short m_anchoDelTile;

		/// <summary>
		/// El alto de cada tile.
		/// </summary>
		private short m_altoDelTile;

		/// <summary>
		/// La imagen que contiene el tileset
		/// </summary>
		private Superficie m_superficie;

		/// <summary>
		/// Contiene los atributos de cada tile.
		/// </summary>
		private Tile[] m_tiles;
        #endregion

        #region Properties
        /// <summary>
        /// Devuelve la Surface de el tileset.
        /// </summary>
        public Superficie Imagen
        {
            get
            {
                return m_superficie;
            }
        }

        public Tile[] Tiles
        {
            get
            {
                return m_tiles;
            }
        }

        /// <summary>
        /// Alto del tile
        /// </summary>
        public short AltoDelTile
        {
            get
            {
                return m_altoDelTile;
            }
        }

        /// <summary>
        /// Ancho del tile
        /// </summary>
        public short AnchoDelTile
        {
            get
            {
                return m_anchoDelTile;
            }
        }

        /// <summary>
        /// Devuelve el id del tileset (agua, tierra, pasto, etc)
        /// </summary>
        public short Id
        {
            get
            {
                return m_id;
            }
        }
        #endregion

        #region Constructores
        /// <summary>
		/// Constructor de la clase.
		/// </summary>
		public Tileset()
		{
        }
        #endregion

        #region Destructor - libera recursos
        /// <summary>
		/// Destructor de la clase. 
		/// </summary>
		~Tileset()
		{
			Log.Instancia.Debug("Bye tileset");
			this.Dispose();
		}

		/// <summary>
		/// Libera la imagen usada.
		/// </summary>
		public virtual void Dispose()
		{
			//Log.Instancia.Debug("dspose tileset");
			//m_superficie.Dispose();
        }
        #endregion

        #region Metodos
        /// <summary>
		/// Carga el tileset, dado el path especificado.
		/// Devuelve true si tuvo éxito.
		/// </summary>
		/// <param name="tilesetPath">La ruta completa el tileset.</param>
		public bool Cargar(string tilesetPath)
		{

			XmlTextReader lector = new XmlTextReader(tilesetPath);
			int id = 0;
			while (lector.Read())
			{
				if (lector.NodeType == XmlNodeType.Element)
				{
					if (lector.Name == "tileset")
					{
						lector.MoveToAttribute("name");
						if (lector.Name == "name")
						{
							m_nombre = lector.Value;
							Log.Instancia.Debug("Tileset: Nombre = " + m_nombre);

							switch (m_nombre.ToLower())
							{
								case "tierra":
									m_id = Res.TLS_TIERRA;
									break;

								case "agua":
									m_id = Res.TLS_AGUA;
									break;

								case "pasto":
									m_id = Res.TLS_PASTO;
									break;

								case "arboles":
									m_id = Res.TLS_ARBOLES;
									break;

								case "unidades":
									m_id = Res.TLS_UNIDADES;
									break;

								case "piedras":
									m_id = Res.TLS_PIEDRAS;
									break;

								case "texturas":
									m_id = Res.TLS_TEXTURAS;
									break;

								case "piedras2":
									m_id = Res.TLS_PIEDRAS2;
									break;

								case "enfermeria":
									m_id = Res.TLS_ENFERMERIA;
									break;

								case "edificios":
									m_id = Res.TLS_EDIFICIOS;
									break;

								case "invalidados":
									m_id = Res.TLS_INVALIDADO;
									break;
                                case "fuerte":
                                    m_id = Res.TLS_FUERTE;
                                    break;
							}
						}

						lector.MoveToAttribute("tilewidth");
						if (lector.Name == "tilewidth")
						{
							m_anchoDelTile = Convert.ToInt16(lector.Value);
							Log.Instancia.Debug("Tileset: Ancho del tile = " + m_anchoDelTile);
						}

						lector.MoveToAttribute("tileheight");
						if (lector.Name == "tileheight")
						{
							m_altoDelTile = Convert.ToInt16(lector.Value);
							Log.Instancia.Debug("Tileset: Alto del Tile = " + m_altoDelTile);
						}
					}

					if (lector.Name == "image")
					{
						lector.MoveToAttribute("source");

						if (lector.Name == "source")
						{
							string imageSource = Utilidades.ObtenerPath(Path.Combine(Programa.PATH_ESCENARIOS, lector.Value));
							if (imageSource == null)
							{
								Log.Instancia.Error("No existe la imagen del tileset " + lector.Value);
								return false;
							}
							Log.Instancia.Debug("Tileset: Imagen = " + imageSource);
							if (m_superficie != null)
							{
                               
								//m_superficie.Dispose();
								m_superficie = null;
							}

							m_superficie = AdministradorDeRecursos.Instancia.ObtenerImagen(imageSource);
							if (m_superficie == null)
							{
								Log.Instancia.Error("No se pudo cargar la imagen " + imageSource);
							}
							//Creo el array de tiles dependiendo de cuantos haya en la imagen
							m_tiles = new Tile[(m_superficie.Alto / m_altoDelTile) * (m_superficie.Ancho / m_anchoDelTile)];

						}

					}

					if (lector.Name == "tile")
					{
						lector.MoveToAttribute("id");

						if (lector.Name == "id")
						{
							id = Convert.ToInt16(lector.Value);
							m_tiles[id] = new Tile();
						}

						while (lector.Read() && !(lector.NodeType == XmlNodeType.EndElement && lector.Name == "tile"))
						{
							if (lector.NodeType == XmlNodeType.Element && lector.Name == "property")
							{

								lector.MoveToAttribute("name");

								if (lector.Value.ToLower() == "id" || lector.Value.ToLower() == "unidad")
								{
									lector.MoveToAttribute("value");
									if (lector.Value == "TILES_VECINOS")
									{
										m_tiles[id].Id = Res.TILE_DEBUG_ID_TILES_VECINOS;
									}

									if (lector.Value == "CAMINO_A_SEGUIR")
									{
										m_tiles[id].Id = Res.TILE_DEBUG_ID_CAMINO_A_SEGUIR;
									}

									if (lector.Value == "PATRICIO")
									{
										m_tiles[id].Id = Res.TILE_UNIDADES_ID_PATRICIO;
									}

									if (lector.Value == "ENFERMERIA")
									{
										m_tiles[id].Id = Res.TILE_INVALIDADOS_ID_ENFERMERIA;
									}

									if (lector.Value == "CASA")
									{
										m_tiles[id].Id = Res.TILE_INVALIDADOS_ID_CASA;
									}

									if (lector.Value == "INGLES")
									{
										m_tiles[id].Id = Res.TILE_UNIDADES_ID_INGLES;
									}
								}

								if (lector.Value.ToLower() == "cantidad")
								{
									lector.MoveToAttribute("value");
									m_tiles[id].Cantidad = Convert.ToInt16(lector.Value);
								}
							}
						}
					}
				}
			}

			lector.Close();
			return true;
		}

		/// <summary>
		/// Devuelve el rectángulo de la Surface conteniendo todo el tileset a la que
		/// pertenece el tile dado.
		/// </summary>
		/// <param name="Id">el Id del tile a devolver</param>
		public Rectangle ObtenerRectanguloDelTile(int id)
		{
			Rectangle destRect = new Rectangle();

			destRect.Y = ((id % (m_superficie.Alto / m_altoDelTile)) * m_anchoDelTile);
			destRect.X = ((id / (m_superficie.Alto / m_altoDelTile)) * m_anchoDelTile);
			destRect.Height = m_altoDelTile;
			destRect.Width = m_anchoDelTile;

			return destRect;
        }
        #endregion
    }
}