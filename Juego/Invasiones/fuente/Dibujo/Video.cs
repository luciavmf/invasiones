using System;
using System.Collections.Generic;
using System.Text;
using Tao.Sdl;
using Invasiones.Recursos;
using Invasiones.Map;
using Invasiones.Debug;
using System.Drawing;
using System.Runtime.InteropServices;
using Invasiones.Eventos;

namespace Invasiones.Dibujo
{
	/// <summary>
	/// Es la pantalla donde se va a dibujar todo. Hereda de la clase Imagen.
	/// Representa a la pantalla.
	/// Ver Diagrama de Despliegue del Framework.
	/// </summary>
	public class Video : Superficie
	{
		#region Declaraciones
		/// <summary>
		/// La cantidad de bytes por pixel en la pantalla
		/// </summary>
		private short BITS_POR_PIXEL = 16;

		/// <summary>
		/// Puntero a la estructura Sdl.SDL_VideoInfo que contiene informacin del video.
		/// </summary>
		private static IntPtr s_videoInfo;

		/// <summary>
		/// Profunidad de colores.
		/// </summary>
		private static int s_profundidad;

		/// <summary>
		/// La máscara utilizada para obtener el componente rojo.
		/// </summary>
		private static int s_mascaraR;

		/// <summary>
		/// La máscara utilizada para obtener el componente verde.
		/// </summary>
		private static int s_mascaraG;

		/// <summary>
		/// La máscara utilizada para obtener el componente azul.
		/// </summary>
		private static int s_mascaraB;

		/// <summary>
		/// La máscara utilizada para obtener el componente alpha.
		/// </summary>
		private static int s_mascaraA;

		/// <summary>
		/// Los flags del Video.
		/// </summary>
		private static int s_flags;

		/// <summary>
		/// El alto del video.
		/// </summary>
		private static short s_alto;

		/// <summary>
		/// El ancho del video.
		/// </summary>
		private static short s_ancho;

		/// <summary>
		/// La m?scara utilizada para obtener los colores
		/// </summary>
		private static IntPtr s_formatoDelPixel;
		#endregion

		#region Properties
		/// <summary>
		/// La profundidad de color.
		/// </summary>
		public static int Profundidad
		{
			get
			{
				return s_profundidad;
			}
		}

		/// <summary>
		/// Devuelve la mascara utilizada para el color rojo.
		/// </summary>
		public static int MascaraR
		{
			get
			{
				return s_mascaraR;
			}
		}

		/// <summary>
		/// Devuelve la mascara utilizada para el color verde.
		/// </summary>
		public static int MascaraG
		{
			get
			{
				return s_mascaraG;
			}
		}

		/// <summary>
		/// Devuelve la mascara utilizada para el color azul.
		/// </summary>
		public static int MascaraB
		{
			get
			{
				return s_mascaraB;
			}
		}

		/// <summary>
		/// Devuelve la mascara utilizada para el componente alpha.
		/// </summary>
		public static int MascaraA
		{
			get
			{
				return s_mascaraA;
			}
		}

		public static int Flags
		{
			get
			{
				return s_flags;
			}
		}

		/// <summary>
		/// Devuelve el alto del video.
		/// </summary>
		new public static short Alto
		{
			get
			{
				return s_alto;
			}
		}


		/// <summary>
		/// Devuelve el ancho de la superficie.
		/// </summary>
		new public static short Ancho
		{
			get { return s_ancho; }
		}

		/// <summary>
		/// Devuelve el formato de color.
		/// </summary>
		public static IntPtr FormatoDelPixel
		{
			get
			{
				return s_formatoDelPixel;
			}
		}
		#endregion

		#region Destructor - libera recursos
		/// <summary>
		/// Destructor. Libera todos los recursos. Libera SDL y todos los subsistemas
		/// utilizados.
		/// </summary>
		~Video()
		{
            this.Dispose();
		}

		/// <summary>
		/// Libera todos los sistemas y subsistemas de SDL.
		/// </summary>
		public override void Dispose()
		{
			Log.Instancia.Debug("Bye video - ttf -audio.");

			// Finalizo el motor TTF.
			SdlTtf.TTF_Quit();

			// quit del audio
			Sdl.SDL_QuitSubSystem(Sdl.SDL_INIT_AUDIO);

			Sdl.SDL_Quit();
			GC.SuppressFinalize(this);
		}
		#endregion

		#region Metodos Unsafe
		/// <summary>
		/// Initializa SDL. Devuelve true si esta todo bien.
		/// </summary>
		/// <param name="width">El ancho de la pantalla.</param>
		/// <param name="height">La altura de la pantalla.</param>
		/// <param name="fullscreen">True para pantalla completa.</param>
		unsafe public bool Iniciar(short ancho, short alto, bool pantallaCompleta)
		{

			m_ancho = s_ancho = ancho;
			m_alto = s_alto = alto;

			if (Sdl.SDL_Init(Sdl.SDL_INIT_VIDEO | Sdl.SDL_INIT_TIMER | Sdl.SDL_INIT_AUDIO) != 0)
			{
				return false;
			}

			if (SdlTtf.TTF_Init() == -1)
			{
				return false;
			}

			//Cargo el ícono en pantalla.
			string pathCompleto = Utilidades.ObtenerPath(Programa.PATH_ICONO);

			if (pathCompleto == null)
			{
				System.Console.WriteLine("No se encuentra el archivo.....");
			}
			Sdl.SDL_WM_SetIcon(SdlImage.IMG_Load(pathCompleto), null);


			if (pantallaCompleta)
			{
				m_superficie = Sdl.SDL_SetVideoMode(m_ancho, m_alto, BITS_POR_PIXEL, Sdl.SDL_DOUBLEBUF | Sdl.SDL_FULLSCREEN | Sdl.SDL_HWSURFACE);
			}
			else
			{
				m_superficie = Sdl.SDL_SetVideoMode(m_ancho, m_alto, BITS_POR_PIXEL, Sdl.SDL_DOUBLEBUF | Sdl.SDL_HWSURFACE);
			}

			s_videoInfo = Sdl.SDL_GetVideoInfo();

			s_formatoDelPixel = ((Sdl.SDL_Surface*)m_superficie.ToPointer())->format;

			Sdl.SDL_PixelFormat formato = IntPtrAPixelFormat(s_formatoDelPixel);

			s_profundidad = formato.BitsPerPixel;
			s_mascaraA = formato.Amask;
			s_mascaraR = formato.Rmask;
			s_mascaraG = formato.Gmask;
			s_mascaraB = formato.Bmask;

			s_flags = ((Sdl.SDL_Surface*)m_superficie.ToPointer())->flags;

			if (m_superficie == null)
			{
				return false;
			}

			Sdl.SDL_WM_SetCaption(Texto.Strings[Res.STR_WINDOW_CAPTION], Texto.Strings[Res.STR_WINDOW_CAPTION]);
			return true;
		}
		#endregion

		#region Metodos Override Unsafe
		/// <summary>
		/// Devuelve el área de clip actual.
		/// </summary>
		override unsafe public Rectangle ObtenerClip()
		{
			Rectangle r = new Rectangle();
			r.X = ((Sdl.SDL_Surface*)m_superficie.ToPointer())->clip_rect.x;
			r.Y = ((Sdl.SDL_Surface*)m_superficie.ToPointer())->clip_rect.y;
			r.Width = ((Sdl.SDL_Surface*)m_superficie.ToPointer())->clip_rect.w;
			r.Height = ((Sdl.SDL_Surface*)m_superficie.ToPointer())->clip_rect.h;

			return r;
		}

		/// <summary>
		/// Setea el clip con el rectángulo dado.
		/// </summary>
		/// <param name="i">La posicion I de comienzo del rectangulo.</param>
		/// <param name="j">La posicion J de comienzo del rectangulo.</param>
		/// <param name="w">El ancho del rectangulo</param>
		/// <param name="h">El alto del rectangulo</param>
		unsafe public override void SetearClip(int x, int y, int w, int h)
		{
			Sdl.SDL_Rect rect = new Sdl.SDL_Rect();

			rect.x = (short)x;
			rect.y = (short)y;
			rect.w = (short)w;
			rect.h = (short)h;

			Sdl.SDL_SetClipRect(m_superficie, ref rect);

		}
		#endregion

		#region Metodos
		/// <summary>
		/// Realmente dibuja todo en la pantalla.
		/// </summary>
		public void Refrescar()
		{
			Sdl.SDL_Flip(m_superficie);
		}
		#endregion

		#region Metodos Static
		/// <summary>
		/// Convierte un color pasado por parámetro en el color aceptado por el Video.
		/// </summary>
		/// <param name="color"></param>
		/// <returns></returns>
		public static int ConvertirColor(int color)
		{
			return Sdl.SDL_MapRGB(s_formatoDelPixel, (byte)((color & 0xFF0000) >> 16), (byte)((color & 0xFF00) >> 8), (byte)(color & 0xFF));
		}
		#endregion
	}
}