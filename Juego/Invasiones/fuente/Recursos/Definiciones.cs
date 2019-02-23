//#define MOSTRAR_INFO_MAPA
//#define SINGLE_CHANNEL_FOR_EACH_CHUNK

using System;
using System.Collections.Generic;
using System.Text;
using Invasiones.Dibujo;
using Invasiones.Recursos;

namespace Invasiones.Recursos
{
	class Definiciones
	{
#if DEBUG
        public const bool CHEATS_HABILITADOS = true;
#else
        public const bool CHEATS_HABILITADOS = true;
#endif
        //Colores utilizados.
		public const int COLOR_GRIS = 0xC8C8C8;
		public const int COLOR_ROJO = 0xFF0000;
		public const int COLOR_NEGRO = 0;
		public const int COLOR_BLANCO = 0xFFFFFF;
		public const int COLOR_VERDE = 0x00FF00;
		public const int COLOR_AZUL = 0x0000FF;
		public const int COLOR_CELESTE = 0x00FFFF;
		public const int COLOR_MAGENTA = 0xFF00FF;
		public const int COLOR_TRANSPARENTE = COLOR_MAGENTA;

		public const int OFFSET_OBJETIVOS = 7;
		public const int ANCHO_OBJETIVOS = 410;
		public const int ALTO_OBJETIVOS = 22;

		public const int ESPACIO_ENTRE_LINEAS = 5;

		public const int COLOR_LOADING = COLOR_AZUL;
		public const int COLOR_TITULO = COLOR_BLANCO;
		public const int COLOR_OBJETIVOS = COLOR_NEGRO;

		public const int CUENTA_MOSTRAR_OBJETIVO_INICIO = 50;

		public const int BOTON_OBJETIVOS_Y = 510;

        public const int MENU_PRINCIPAL_Y_OFFSET = 50;

		public const int BORDE_OBJETIVOS = 100;

		public const int CARGANDO_Y = 200;

        public const int TEXTO_AYUDA_Y = 200;
        public const int TEXTO_AYUDA_ITEM_Y = 150;

		/// <summary>
		/// La posicion en y en donde se dibujan todos los títulos.
		/// </summary>
		public const int TITULO_Y = 30;

		public const int JUEGO_PAUSADO_Y = -200;

		public const int GUI_COLOR_MENUS = Definiciones.COLOR_NEGRO;
		public const int GUI_COLOR_SELECCION = Definiciones.COLOR_ROJO;
		public const int GUI_COLOR_TEXTO = Definiciones.COLOR_BLANCO;
		public const int GUI_ALPHA = 128;

		public const int ALPHA_OBJETIVOS = GUI_ALPHA;

		public const int CONFIRMACION_ALPHA = 128;
		public const int CONFIRMACION_ANCHO = 350;
		public const int CONFIRMACION_ALTO = 150;

        public const int TIPS_ALPHA = 100;
        public const int TIPS_ANCHO = 450;
        public const int TIPS_ALTO = 100;

		
		public const int PRESIONE_PARA_CONTINUAR_Y = 200;

		public const int PAGINAS_POR_INTRO = 3;

        public const int TOTAL_TICKS_HASTA_OBJETIVO = 50;


		//Fuentes utilizadas en el juego.
		public enum FNT
		{
			SANS12, 
			SANS14,
			SANS18,
			SANS20,
            SANS24,
			SANS28,
            LBLACK12,
            LBLACK14,
            LBLACK18,
            LBLACK20,
            LBLACK28,
			TOTAL
		}

		//Fuentes utilizadas
        public const int FUENTE_TITULO_OBJETIVOS = (int)FNT.LBLACK28;

		public const int FUENTE_TITULO = (int)FNT.LBLACK28;

        public const int FUENTE_TITULO_AYUDA = (int)FNT.SANS24;

        public const int FUENTE_AYUDA = (int)FNT.SANS18;

		public const int FUENTE_MENU = (int)FNT.SANS20;

		public const int FUENTE_BOTON = (int)FNT.SANS14;

		public const int FUENTE_RECORDATORIO_OBJETIVOS = (int)FNT.SANS14;

        public const int FUENTE_OBJETIVOS = (int)FNT.SANS20;

		public const int FUENTE_GANO = (int)FNT.LBLACK28;

		public const int COLOR_FUENTE_OBJETIVOS = COLOR_BLANCO;

		public const int COLOR_TEXTO_GANO = COLOR_BLANCO;


		//Sirve para mostrar los sprites distintos.
		public enum DIRECCION
		{ 
			N=0,
			NE, 
			E, 
			SE,
			S, 
			SO,
			O, 
			NO,
			CANTIDAD_DIRECCIONES
		}

	}
}
