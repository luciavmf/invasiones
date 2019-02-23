using System;
using System.Collections.Generic;
using System.Text;
using Invasiones.GUI;

namespace Invasiones.Map
{
    /// <summary>
    /// Representa la porción visible del mapa.
    /// </summary>
    public class Camara
    {
        #region Declaraciones
        /// <summary>
        /// La posición X de la cámara.
        /// </summary>
        public int X;

        /// <summary>
        /// La posición Y de la cámara.
        /// </summary>
        public int Y;

        /// <summary>
        /// La posición de inicio en X de la cámara.
        /// </summary>
        private int m_inicioX = 0;

        /// <summary>
        /// La posición de inicio en Y de la cámara
        /// </summary>
        private int m_inicioY = 0;

        /// <summary>
        /// El ancho de la cámara
        /// </summary>
        private int m_ancho = Programa.ANCHO_DE_LA_PANTALLA;

        /// <summary>
        /// El alto de la cámara.
        /// </summary>
        private int m_alto;

        /// <summary>
        /// El borde de la cámara.
        /// </summary>
        private int m_borde = 20;

        /// <summary>
        /// La velocidad a la que se mueve la cámara. La velocidad no puede ser impar.
        /// </summary>
        private int m_velocidad = 20;//6;
        #endregion

        #region Properties
        /// <summary>
        /// La posición en X en donde empieza la pantalla
        /// </summary>
        public int InicioX
        {
            get
            {
                return m_inicioX;
            }

        }

        /// <summary>
        /// La posición en Y en donde empieza la pantalla
        /// </summary>
        public int InicioY
        {
            get
            {
                return m_inicioY;
            }


        }

        /// <summary>
        /// El ancho de la pantalla
        /// </summary>
        public int Ancho
        {
            get
            {
                return m_ancho;
            }
        }

        /// <summary>
        /// El alto de la pantalla
        /// </summary>
        public int Alto
        {
            get
            {
                return m_alto;
            }
        }

        /// <summary>
        /// Devuelve el borde en de la pantalla.
        /// </summary>
        public int Borde
        {
            get
            {
                return m_borde;
            }
        }

        /// <summary>
        /// Devuelve la velocidad a la que se mueve la cámara.
        /// </summary>
        public int Velocidad
        {
            get
            {
                return m_velocidad;
            }
        }
        #endregion

        #region Constructores
        /// <summary>
        /// Constructor.
        /// </summary>
        /// <param name="x">La posición x de la cámara.</param>
        /// <param name="y">La posición y de la cámara.</param>
        public Camara(int x, int y, int alto)
		{
            X = x;
            Y = y;
			m_alto = alto;
        }
        #endregion

        #region Metodos
        /// <summary>
        /// Setea las coordenadas de la cámara. Es utilizado para saber donde se va a
        /// dibujar el m_mapa, en que porción.
        /// </summary>
        /// <param name="i">I inicio de la cámara.</param>
        /// <param name="j">J inicio de la cámara.</param>
        /// <param name="w">Ancho de la cámara.</param>
        /// <param name="h">Alto de la cámara.</param>
        public void SetearCoordenadasDeLaPantalla(short x, short y, short w, short h)
        {
            if (x >= 0)
            {
                m_inicioX = x;
            }
            else
            {
                m_inicioX = 0;
            }


            if (y >= 0)
            {
                m_inicioY = y;
            }
            else
            {
                m_inicioY = 0;
            }


            if (w + x <= Programa.ANCHO_DE_LA_PANTALLA)
            {
                m_ancho = w;
            }
            else
            {
                m_ancho = (Programa.ANCHO_DE_LA_PANTALLA - x);
            }


            if (h + y <= Programa.ALTO_DE_LA_PANTALLA)
            {
                m_alto = h;
            }
            else
            {
                m_alto = (short)(Programa.ALTO_DE_LA_PANTALLA - y);
            }
        }
        #endregion
    }
}