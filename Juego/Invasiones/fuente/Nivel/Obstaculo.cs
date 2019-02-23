using System;
using System.Collections.Generic;
using System.Text;
using Invasiones.Map;
using Invasiones.Dibujo;
using System.Drawing;

namespace Invasiones.Nivel
{
    public class Obstaculo : Objeto
    {

		/// <summary>
		/// El índice dentro de la imagen
		/// </summary>
        private int m_indice;

		/// <summary>
		/// Me dice si es un edificio, para pintarlo de otra manera.
		/// </summary>
		private bool m_esEdificio;

		/// <summary>
		/// Constructor del obstaculo
		/// </summary>
		/// <param name="indice">El indide dentri del tileset</param>
		/// <param name="i">La posicion del tile en i</param>
		/// <param name="j">La posicion del tile en j</param>
		/// <param name="tileset">El tileset al que hacer referencia la imagen.</param>
        public Obstaculo(int indice, int i, int j, ref Tileset tileset)
        {
            m_indice = indice;

			m_frameAlto = tileset.AltoDelTile;
			m_frameAncho = tileset.AnchoDelTile;

			m_posEnTileFisico.X = i;
			m_posEnTileFisico.Y = j;

			m_imagen = tileset.Imagen;

			Point p = TransformarIJEnXY(m_posEnTileFisico.X, m_posEnTileFisico.Y);
           
            m_posEnMundoPlano.X = p.X;
            m_posEnMundoPlano.Y = p.Y;
            if (tileset.Id == Res.TLS_EDIFICIOS || tileset.Id == Res.TLS_ENFERMERIA || tileset.Id == Res.TLS_FUERTE)
			{
				m_esEdificio = true;
			}

			if (tileset.Id == Res.TLS_DEBUG)
			{
				m_imagen = null;
			}
			
			ActualizarPosicionXY();

        }

		/// <summary>
		/// Actualiza la posición en XY del objeto (la posición del mapa)
		/// </summary>
        public override void Actualizar()
        {
            ActualizarPosicionXY();
        }

		/// <summary>
		/// Dibuja el obstaculo en pantalla.
		/// </summary>
		/// <param name="g">La referencia al Video</param>
        public override void Dibujar(Video g)
        {
			if (m_imagen != null)
			{

				m_imagen.SetearClip(m_indice * m_frameAncho, 0, m_frameAncho, m_frameAlto);
				if (m_esEdificio)
				{
					g.Dibujar(m_imagen, m_x /*+ s_mapa.TileAncho / 2*/, m_y - m_frameAlto + s_mapa.TileAlto / 2, 0);
				}
				else
				{
					g.Dibujar(m_imagen, m_x - m_frameAncho / 2 + s_mapa.TileAncho / 2, m_y - m_frameAlto + s_mapa.TileAlto / 2, 0);
				}
			}
        }
    }
}
