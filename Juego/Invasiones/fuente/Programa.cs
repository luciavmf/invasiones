using System;
using System.Collections.Generic;
using System.Text;

namespace Invasiones
{
    /// <summary>
    /// La clase que contiene el punto de entrada de la aplicación.
    /// </summary>
    public class Programa
    {
        /// <summary>
        /// La cantidad de FPS por default.
        /// </summary>
        public const int FPS_POR_DEFECTO = 20;

        /// <summary>
        /// El path donde esta a la data.
        /// </summary>
        public const string PATH_DATA_DEL_PROG = "..\\..\\..\\Data";

        /// <summary>
        /// El path donde esta a la data.
        /// </summary>
        public const string PATH_ICONO = "imagenes\\icono.png";

        /// <summary>
        /// El path donde esta la data.
        /// </summary>
        public const string PATH_DATA = "Data";

        public const string PATH_ESCENARIOS = "escenarios";

		public const string PATH_NIVEL = "nivel";

        public const string ARCHIVO_XML_TEXTOS = "strings.xml";

        public const string ARCHIVO_XML_RECURSOS = "res.xml";

        /// <summary>
        /// El ancho de la pantalla.
        /// </summary>
        public const short ANCHO_DE_LA_PANTALLA = 1024;

        /// <summary>
        /// El alto de la pantalla.
        /// </summary>
        public const short ALTO_DE_LA_PANTALLA = 768;

        /// <summary>
        /// Si el juego es fullcreen o no.. 
        /// </summary>
#if (DEBUG)
        public const bool FULLSCREEN = false;
#else
		public const bool FULLSCREEN = true;
#endif


		static void Main(string[] args)
        {
            GameFrame gameFrame = new GameFrame(ANCHO_DE_LA_PANTALLA, ALTO_DE_LA_PANTALLA, FPS_POR_DEFECTO, FULLSCREEN);
        }

    }
}
