using System;
using System.Collections.Generic;
using System.Text;
using Invasiones.Dibujo;

namespace Invasiones.GUI
{
	public abstract class CajaGUI
	{

		/// <summary>
		/// Posicion en donde se va a pintar el menu de confirmación.
		/// </summary>
		protected int m_y;

		/// <summary>
		/// Posicion en donde se va a pintar el menu de confirmación.
		/// </summary>
		protected int m_x;

		/// <summary>
		/// La fuente utilizada para escribir el nombre del boton.
		/// </summary>
		protected Fuente m_fuente;

		/// <summary>
		/// El ancho del boton. Es el ancho de la imagen, si la imagen esta seteada.
		/// </summary>
		protected int m_ancho;

		/// <summary>
		/// El alto del boton. Es el alto de la imagen, si la imagen esta seteada.
		/// </summary>
		protected int m_alto;

		/// <summary>
		/// La imagen de fondo del botón, cuando no esta el puntero del mouse sobre la imagen.
		/// </summary>
		protected Superficie m_imagen;

		/// <summary>
		/// El nombre del botón.
		/// </summary>
		protected int m_leyenda;

		/// <summary>
		/// Setea la posicion de la caja en x, y tomados desde el ancla.
		/// </summary>
		/// <param name="x">La posicion en x.</param>
		/// <param name="y">La posicion en y.</param>
		/// <param name="ancla">El ancla desde donde tomar el x y el y</param>
		public abstract void SetearPosicion(int x, int y, int ancla);

		/// <summary>
		/// Actualiza segun los eventos de entrada.
		/// </summary>
		public abstract int Actualizar();

		/// <summary>
		/// Dibuja la caja
		/// </summary>
		public abstract void Dibujar(Video g);

		/// <summary>
		/// Devuelve el alto de la caja.
		/// </summary>
        public int Alto
        {
            get
            {
                return m_alto;
            }
        }

		/// <summary>
		/// Devuelve el ancho de la caja.
		/// </summary>
        public int Ancho
        {
            get
            {
                return m_ancho;
            }
        }

	}
}
