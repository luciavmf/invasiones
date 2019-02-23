using System;
using System.Collections.Generic;
using System.Text;
using System.Drawing;
using Invasiones.Dibujo;
using Invasiones.Recursos;
using Invasiones.Debug;
using Invasiones.Sprites;

namespace Invasiones.Nivel
{
	/// <summary>
	/// Representa a una orden que debe cumplir el 
	/// </summary>
	public class Orden
	{
        /// <summary>
        /// El tipo de orden que se le puede dar a un grupo o unidad.
        /// </summary>
		public enum TIPO
		{
			INVALIDA = -1,
			TOMAR_OBJETO, //0
			MOVER, //1
			ATACAR, //2
			PATRULLAR, //3
			SANAR, //4
            TRIGGER,
            MATAR
		}

        private Superficie m_imagen;

		/// <summary>
		/// El id de la orden: TOMAR, MOVER, etc..
		/// </summary>
		private TIPO m_id;

		/// <summary>
		/// El punto a donde se tiene que cumplir la orden ID.
		/// </summary>
		private Point m_punto;

		/// <summary>
		/// Get del tipo de orden.
		/// </summary>
		public TIPO Id
		{
			get
			{
				return m_id;
			}
		}

        public AnimObjeto Animacion
        {
            get {
                return m_animacion;
            }
        }

		/// <summary>
		/// Get y set del punto
		/// </summary>
		public Point Punto
		{
			get
			{
				return m_punto;
			}
        }

        /// <summary>
        /// La imagen de la orden.. Para cuando quiero tomar un objeto.
        /// </summary>
        public Superficie Imagen
        {
            get
            {
                return m_imagen;
            }
        }
		/// <summary>
		/// Crea una nueva orden.
		/// </summary>
		/// <param name="tipo">EL tipo de orden.</param>
		/// <param name="x">El x en donde se tiene que cumplir la orden.</param>
		/// <param name="y">El y en donde se tiene que cumplir la orden</param>
		public Orden(Orden.TIPO tipo, int x, int y)
		{
			m_id = tipo;
			m_punto = new Point(x, y);
            m_imagen = null;
		}

        public int Ancho
        {
            get
            {
                return m_ancho;
            }
        }

        private int m_ancho;

        /// <summary>
        /// Crea una nueva orden.
        /// </summary>
        /// <param name="tipo">EL tipo de orden.</param>
        /// <param name="x">El x en donde se tiene que cumplir la orden.</param>
        /// <param name="y">El y en donde se tiene que cumplir la orden</param>
        public Orden(Orden.TIPO tipo, int x, int y, int ancho)
        {
            m_id = tipo;
            m_punto = new Point(x, y);
            m_imagen = null;
            m_ancho = ancho;
        }

        /// <summary>
        /// Crea una nueva orden.
        /// </summary>
        /// <param name="tipo">EL tipo de orden.</param>
        /// <param name="x">El x en donde se tiene que cumplir la orden.</param>
        /// <param name="y">El y en donde se tiene que cumplir la orden</param>
        public Orden(Orden.TIPO tipo, int x, int y, string path)
        {
            m_id = tipo;
            m_punto = new Point(x, y);
            m_imagen = AdministradorDeRecursos.Instancia.ObtenerImagen(Utilidades.ObtenerPath(path));

            if (m_imagen == null)
            {
                Log.Instancia.Debug("No se puede obtener la imagen que esta en el nivel.");
            }
        }


        private AnimObjeto m_animacion;


        /// <summary>
        /// Crea una nueva orden.
        /// </summary>
        /// <param name="tipo">EL tipo de orden.</param>
        /// <param name="x">El x en donde se tiene que cumplir la orden.</param>
        /// <param name="y">El y en donde se tiene que cumplir la orden</param>
        public Orden(Orden.TIPO tipo, int x, int y, AnimObjeto animacion)
        {
            m_id = tipo;
            m_punto = new Point(x, y);
            m_imagen = null;
            m_animacion = animacion;
        }
	}
}
