using System;
using System.Collections.Generic;
using System.Text;
using Invasiones.Dibujo;
using Tao.Sdl;
using Invasiones.Sprites;
using System.IO;
using Invasiones.Debug;
using Invasiones.Map;
using System.Drawing;
using System.Runtime.InteropServices;
using Invasiones.Recursos;

namespace Invasiones.Dibujo
{
	/// <summary>
	/// Funciona como un wrapper a una SDL_Surface. Representa una superficie que se
	/// puede pintar con una imagen levantada desde un archivo, texto, o alguna otra
	/// superficie.
	/// Esta clase es utilizada por todas las demás clases que tengan un método
	/// DibujarUltimoPath() o que tengan una imagen.
	/// </summary>
	public class Superficie
    {
        #region Declaraciones
        /// <summary>
		/// Punto de ancla: centro horizontal
		/// </summary>
		public const short H_CENTRO = 0x1 << 0;

		/// <summary>
		/// Punto de ancla: centro vertical
		/// </summary>
		public const short V_CENTRO = 0x1 << 1;

		/// <summary>
		/// Punto de ancla: fondo vertical
		/// </summary>
		public const short V_FONDO = 0x1 << 2;

		/// <summary>
		/// Punto de ancla: fondo horizontal
		/// </summary>
		public const short H_FONDO = 0x1 << 3;

		/// <summary>
		/// Puntero a la SDL_Surface.
		/// </summary>
		protected IntPtr m_superficie;

		/// <summary>
		/// Si la imagene es mutable.
		/// </summary>
		protected bool m_mutable;

		/// <summary>
		/// La altura de la imagen.
		/// </summary>
		protected short m_alto;

		/// <summary>
		/// El ancho de la imagen.
		/// </summary>
		protected short m_ancho;

		/// <summary>
		/// El área de clip de la imagen.
		/// </summary>
		protected Sdl.SDL_Rect m_areaDeClip;

		/// <summary>
		/// La fuente utilizada para renderizar textos sobre esta superficie.
		/// </summary>
		protected Fuente m_fuente;

		/// <summary>
		/// El color seteado. Utilizado cuando se llaman los métodos de pintado de
		/// rectangulos, por ejemplo.
		/// </summary>
		protected int m_color;

        private bool m_vacia;
        #endregion

        #region Constructores
        /// <summary>
		/// Class constructor
		/// </summary>
		/// <param name="nombreArchivo">El archivo que contiene a la imagen.</param>
		unsafe public Superficie(string nombreArchivo)
		{
			if (File.Exists(nombreArchivo))
			{
				IntPtr tempSuperficie = SdlImage.IMG_Load(nombreArchivo);

				//Esto sirve para setear un color que sea transparente en toda la imagen
				//Sdl.SDL_SetAlpha(tempSurface, Sdl.SDL_SRCALPHA | Sdl.SDL_RLEACCEL, 200);

				//le seteamos el color MAGENTA como trasparente
				//Sdl.SDL_SetColorKey(tempSurface, Sdl.SDL_SRCCOLORKEY | Sdl.SDL_RLEACCEL, Sdl.SDL_MapRGB(((Sdl.SDL_Surface *)tempSurface.ToPointer())->format, 255, 0, 255));

				//Lo cargamos desde no temporal porque es más rápido convertirlo al formato nativo aca.
				//En caso conrtario, la imagen se tiene que convertir a formato nativo cada vez que se hace el blit
				//m_superficie = Sdl.SDL_DisplayFormatAlpha(tempSuperficie); //Carag la informacion de un png de24 bits.
				m_superficie = Sdl.SDL_DisplayFormat(tempSuperficie);
				Sdl.SDL_FreeSurface(tempSuperficie);
				m_ancho = (short)((Sdl.SDL_Surface*)m_superficie.ToPointer())->w;
				m_alto = (short)((Sdl.SDL_Surface*)m_superficie.ToPointer())->h;

				m_areaDeClip.x = 0;
				m_areaDeClip.y = 0;
				m_areaDeClip.w = m_ancho;
				m_areaDeClip.h = m_alto;

			}
			else
			{
				Log.Instancia.Error("Error. NO existe el archivo " + nombreArchivo);
			}
		}

        /// <summary>
        /// Class constructor
        /// </summary>
        /// <param name="nombreArchivo">El archivo que contiene a la imagen.</param>
        unsafe public Superficie(string nombreArchivo, bool usarAlpha)
        {
            if (File.Exists(nombreArchivo))
            {
                IntPtr tempSuperficie = SdlImage.IMG_Load(nombreArchivo);

                //Esto sirve para setear un color que sea transparente en toda la imagen
                //Sdl.SDL_SetAlpha(tempSurface, Sdl.SDL_SRCALPHA | Sdl.SDL_RLEACCEL, 200);

                //le seteamos el color MAGENTA como trasparente
                //Sdl.SDL_SetColorKey(tempSurface, Sdl.SDL_SRCCOLORKEY | Sdl.SDL_RLEACCEL, Sdl.SDL_MapRGB(((Sdl.SDL_Surface *)tempSurface.ToPointer())->format, 255, 0, 255));

                //Lo cargamos desde no temporal porque es más rápido convertirlo al formato nativo aca.
                //En caso conrtario, la imagen se tiene que convertir a formato nativo cada vez que se hace el blit
                if (usarAlpha)
                {
                    m_superficie = Sdl.SDL_DisplayFormatAlpha(tempSuperficie); //Carag la informacion de un png de24 bits.
                }
                else
                {
                    m_superficie = Sdl.SDL_DisplayFormat(tempSuperficie);
                }
                Sdl.SDL_FreeSurface(tempSuperficie);
                m_ancho = (short)((Sdl.SDL_Surface*)m_superficie.ToPointer())->w;
                m_alto = (short)((Sdl.SDL_Surface*)m_superficie.ToPointer())->h;

                m_areaDeClip.x = 0;
                m_areaDeClip.y = 0;
                m_areaDeClip.w = m_ancho;
                m_areaDeClip.h = m_alto;

            }
            else
            {
                Log.Instancia.Error("Error. No existe el archivo " + nombreArchivo);
            }
        }

		/// <summary>
		/// Crea una superficie copiando otra
		/// </summary>
		/// <param name="sup">La superficie a copiar.</param>
		unsafe public Superficie(Superficie sup)
		{
			if (sup != null)
			{

				m_superficie = (IntPtr)sup.m_superficie;

				m_alto = sup.m_alto;
				m_ancho = sup.m_ancho;

				m_areaDeClip.x = 0;
				m_areaDeClip.y = 0;
				m_areaDeClip.w = m_ancho;
				m_areaDeClip.h = m_alto;
			}
        }

        /// <summary>
        /// Constructor de la clase. Por defecto, no guarda ninguna Imagen ni Fuente.
        /// Setea un color por defecto.
        /// </summary>
        unsafe public Superficie(int ancho, int alto)
        {
			m_mutable = true;
            m_superficie = Sdl.SDL_CreateRGBSurface(Video.Flags, ancho, alto, Video.Profundidad, Video.MascaraR, Video.MascaraG, Video.MascaraB, Video.MascaraA);

            m_ancho = (short)ancho;
            m_alto = (short)alto;

            m_vacia = true;

            m_areaDeClip.x = 0;
            m_areaDeClip.y = 0;
            m_areaDeClip.w = m_ancho;
            m_areaDeClip.h = m_alto;
        }

        /// <summary>
        /// Constructor de la clase. Por defecto no se puede crear una Superficie sin nada.
        /// </summary>
        protected Superficie()
        {

        }
        #endregion

        #region Destructor - libera recursos
        /// <summary>
		/// Destructor. 
		/// </summary>
		~Superficie()
		{
			if (m_mutable)
			{
				this.Dispose();
			}
		}

		/// <summary>
		/// Libera cualquier recurso que este utilizando.
		/// </summary>
		public virtual void Dispose()
		{
			Log.Instancia.Debug("dispose superficie");
			if (m_superficie != IntPtr.Zero)
			{
				Log.Instancia.Debug("Elimino superficie: " + m_superficie);
				Sdl.SDL_FreeSurface(m_superficie);
				m_superficie = IntPtr.Zero;
				GC.SuppressFinalize(this);
			}
        }
        #endregion

        #region Metodos Virtual
        /// <summary>
		/// Devuelve el área de clip actual.
		/// </summary>
		public virtual Rectangle ObtenerClip()
		{
			Rectangle r = new Rectangle();
			r.X = m_areaDeClip.x;
			r.Y = m_areaDeClip.y;
			r.Width = m_areaDeClip.w;
			r.Height = m_areaDeClip.h;

			return r;
		}

		/// <summary>
		/// Setea el clip con el rectángulo dado.
		/// </summary>
		/// <param name="x">La posicion x de comienzo del rectángulo.</param>
		/// <param name="y">La posicion y de comienzo del rectángulo.</param>
		/// <param name="w">El ancho del rectángulo</param>
		/// <param name="h">El alto del rectángulo</param>
		public virtual void SetearClip(int x, int y, int w, int h)
		{
			m_areaDeClip.x = (short)x;
			m_areaDeClip.y = (short)y;
			m_areaDeClip.w = (short)w;
			m_areaDeClip.h = (short)h;
		}

		/// <summary>
		/// Setea el clip con el rectángulo dado.
		/// </summary>
		/// <param name="rect">el rectángulo que representa e area de clip.</param>
		public virtual void SetearClip(Rectangle rect)
		{
			m_areaDeClip.x = (short)rect.X;
			m_areaDeClip.y = (short)rect.Y;
			m_areaDeClip.w = (short)rect.Width;
			m_areaDeClip.h = (short)rect.Height;
        }
        #endregion

        #region Metodos
        /// <summary>
		/// Llena el área comprendida por el rectángulo dado con el color dado.
		/// </summary>
		/// <param name="i">La posición i de comienzo del rectángulo.</param>
		/// <param name="j">La posición j de comienzo del rectángulo.</param>
		/// <param name="w">El ancho del rectángulo.</param>
		/// <param name="h">La altura del rectángulo.</param>
		public void LlenarRectangulo(int x, int y, int w, int h)
		{
			Sdl.SDL_Rect destRect;
			destRect.x = (short)x;
			destRect.y = (short)y;
			destRect.w = (short)w;
			destRect.h = (short)h;

			Sdl.SDL_FillRect(m_superficie, ref destRect, m_color);
        }

        /// <summary>
        /// Dibuja una superficie en la posicion dada por parametro.
        /// </summary>
        /// <param name="surface">la superficie a dibujar</param>
        /// <param name="rectX">Comienzo x del rectángulo</param>
        /// <param name="rectY">Comienzo y del rectángulo</param>
        /// <param name="rectW">Ancho del rectangulo</param>
        /// <param name="rectH">Alto del rectángulo</param>
        /// <param name="destX">X del punto a dibujar</param>
        /// <param name="destY">Y del punto a dibujar</param>
        public bool Dibujar(Superficie surface, int rectX, int rectY, int rectW, int rectH, int destX, int destY)
        {
            Sdl.SDL_Rect dstRect;

            dstRect.x = (short)destX;
            dstRect.y = (short)destY;
            dstRect.h = dstRect.w = 0;

            Sdl.SDL_Rect srcRect;
            srcRect.x = (short)rectX;
            srcRect.y = (short)rectY;
            srcRect.w = (short)rectW;
            srcRect.h = (short)rectH;

            Sdl.SDL_BlitSurface(surface.m_superficie, ref srcRect, m_superficie, ref dstRect);

            return true;
        }

        /// <summary>
        /// Dibuja el recuadro del rectángulo dado.
        /// </summary>
        /// <param name="x">La posición de comienzo x del rectángulo.</param>
        /// <param name="y">La posición de comienzo y del rectángulo.</param>
        /// <param name="w">El ancho del rectángulo.</param>
        /// <param name="h">El alto del rectángulo.</param>
        /// <param name="ancla">El ancla desde donde tomar el la posicion (x, y).</param>
        public void DibujarRectangulo(int x, int y, int w, int h, int ancla)
        {
            if (w == 0 || h == 0)
            {
                return;
            }

            if ((ancla & Superficie.H_CENTRO) != 0)
            {
                x += (m_ancho / 2 - w / 2);
            }

            if ((ancla & Superficie.V_CENTRO) != 0)
            {
                y += (m_alto / 2 - h / 2);
            }

			

            Sdl.SDL_Rect srcRect;

            srcRect.x = (short)x;
            srcRect.w = (short)(w - 1);
            srcRect.y = (short)y;
            srcRect.h = 1;
            Sdl.SDL_FillRect(m_superficie, ref srcRect, m_color);

            srcRect.x = (short)x;
            srcRect.w = (short)(w - 1);
            srcRect.y = (short)(h + y - 1);
            srcRect.h = 1;
            Sdl.SDL_FillRect(m_superficie, ref srcRect, m_color);

            srcRect.x = (short)x;
            srcRect.w = (short)1;
            srcRect.y = (short)y;
            srcRect.h = (short)(h - 1);
            Sdl.SDL_FillRect(m_superficie, ref srcRect, m_color);

            srcRect.x = (short)(w + x - 1);
            srcRect.w = (short)1;
            srcRect.y = (short)y;
            srcRect.h = (short)(h);
            Sdl.SDL_FillRect(m_superficie, ref srcRect, m_color);
        }

        /// <summary>
        /// Devuelve y setea el color actual.
        /// El color esta guardado como 0xRRGGBB
        /// </summary>
        /// <param name="value">El color 0xRRGGBB a setear.</param>
        public void SetearColor(int color)
        {

            m_color = Sdl.SDL_MapRGB(Video.FormatoDelPixel, (byte)((color & 0xFF0000) >> 16), (byte)((color & 0x00FF00) >> 8), (byte)((color & 0x0000FF)));

            if (m_fuente != null)
            {
                m_fuente.SetearColor((byte)((color & 0xFF0000) >> 16), (byte)((color & 0x00FF00) >> 8), (byte)((color & 0x0000FF)), 0);

            }
        }

        /// <summary>
        /// Devuelve y setea la Font actual, con la que escribira textos.
        /// </summary>
        public void SetearFuente( Fuente f, int color)
        {
			
            m_fuente = null;
            m_fuente = f;
			if (m_fuente != null)
			{
				m_fuente.SetearColor((byte)((color & 0xFF0000) >> 16), (byte)((color & 0x00FF00) >> 8), (byte)((color & 0x0000FF)), 0);
			}
        }

        /// <summary>
        /// Devuelve el alto de la superficie.
        /// </summary>
        public short Alto
        {
            get
            {
                return m_alto;
            }
        }

        /// <summary>
        /// Devuelve el ancho de la superficie.
        /// </summary>
        public short Ancho
        {
            get
            {
                return m_ancho;
            }
        }

        /// <summary>
        /// Le setea el alpha a la imagen.
        /// </summary>
        /// <param name="nivel"></param>
        public void SetearAlpha(byte nivel)
        {
            Sdl.SDL_SetAlpha(m_superficie, Sdl.SDL_SRCALPHA | Sdl.SDL_RLEACCEL, nivel);
        }
        #endregion

        #region Metodos Unsafe
        /// <summary>
		/// Llena el área comprendida por el rectángulo dado con el color dado.
		/// No funciona con imagenes transparentes.
		/// </summary>
		/// <param name="x">La posición x de comienzo del rectángulo.</param>
		/// <param name="y">La posición y de comienzo del rectángulo.</param>
		/// <param name="w">El ancho del rectángulo.</param>
		/// <param name="h">La altura del rectángulo.</param>
		/// <param name="color">El color en formato 0xRRGGBB.</param>
		/// <param name="aplha">El alfa. De 0 (completamente transparente) a 255 (completamente opaco).</param>
		/// <param name="ancla">El ancla de donde tomar el (x, y).</param>
		unsafe public void LlenarRectangulo(int x, int y, int w, int h, byte alpha, int ancla)
		{
			if (m_vacia)
			{
				Sdl.SDL_Rect rec = new Sdl.SDL_Rect();
				rec.x = 0;
				rec.y = 0;
				rec.w = m_ancho;
				rec.h = m_alto;
				Sdl.SDL_SetAlpha(m_superficie, Sdl.SDL_SRCALPHA | Sdl.SDL_RLEACCEL, 100);
				Sdl.SDL_FillRect(m_superficie, ref rec, m_color);
				return;
			}


			Sdl.SDL_Rect srcRect = new Sdl.SDL_Rect();

			srcRect.w = (short)w;
			srcRect.h = (short)h;

			int flags = ((Sdl.SDL_Surface*)m_superficie.ToPointer())->flags | Sdl.SDL_HWSURFACE;
			int profundidad = ((Sdl.SDL_PixelFormat*)((Sdl.SDL_Surface*)m_superficie.ToPointer())->format.ToPointer())->BitsPerPixel;
			int r = ((Sdl.SDL_PixelFormat*)((Sdl.SDL_Surface*)m_superficie.ToPointer())->format.ToPointer())->Rmask;
			int g = ((Sdl.SDL_PixelFormat*)((Sdl.SDL_Surface*)m_superficie.ToPointer())->format.ToPointer())->Gmask;
			int b = ((Sdl.SDL_PixelFormat*)((Sdl.SDL_Surface*)m_superficie.ToPointer())->format.ToPointer())->Bmask;
			int a = ((Sdl.SDL_PixelFormat*)((Sdl.SDL_Surface*)m_superficie.ToPointer())->format.ToPointer())->Amask;

			IntPtr tempSurface = Sdl.SDL_CreateRGBSurface(flags, w, h, profundidad, r, g, b, a);

			Sdl.SDL_FillRect(tempSurface, ref srcRect, m_color);
			Sdl.SDL_SetAlpha(tempSurface, Sdl.SDL_SRCALPHA | Sdl.SDL_RLEACCEL, alpha);

			Sdl.SDL_Rect desRect = new Sdl.SDL_Rect();

			desRect.x = (short)x;
			desRect.y = (short)y;


			if ((ancla & Superficie.H_CENTRO) != 0)
			{
				desRect.x += (short)(m_ancho / 2 - w / 2);
			}

			if ((ancla & Superficie.V_CENTRO) != 0)
			{
				desRect.y += (short)(m_alto / 2 - h / 2);
			}

			Sdl.SDL_BlitSurface(tempSurface, ref srcRect, m_superficie, ref desRect);
			Sdl.SDL_FreeSurface(tempSurface);

		}

		/// <summary>
		/// Llena el área de clip con el color dado.
		/// </summary>
		/// <param name="color">El color en 0XRRGGBB.</param>
		unsafe public void LlenarRectangulo(int color)
		{
			m_areaDeClip = ((Sdl.SDL_Surface*)m_superficie.ToPointer())->clip_rect;
			Sdl.SDL_FillRect(m_superficie, ref m_areaDeClip, color);
		}

		/// <summary>
		///  Dibuja la supericie dada en el punto (x, y) tomados desde el ancla
		/// </summary>
		/// <param name="surface">la superficie a dibujar</param>
		/// <param name="x">La posición x</param>
		/// <param name="y">La posición y/param>
		/// <param name="ancla">El ancla desde donde tomar el x, y</param>
		/// <returns>true si pudo dibujar</returns>
		unsafe public bool Dibujar(Superficie surface, int x, int y, int ancla)
		{
			Sdl.SDL_Rect dstRect;

			dstRect.x = (short)x;
			dstRect.y = (short)y;
			dstRect.h = dstRect.w = 0;

			Sdl.SDL_Rect srcRect;


			if ((ancla & Superficie.H_CENTRO) != 0)
			{
				dstRect.x += (short)(m_ancho / 2 - surface.m_ancho / 2);
			}

			if ((ancla & Superficie.V_CENTRO) != 0)
			{
				dstRect.y += (short)(m_alto / 2 - surface.m_alto / 2);
			}

			if ((ancla & Superficie.V_FONDO) != 0)
			{
				dstRect.y += (short)(m_alto - surface.m_alto);
			}

			srcRect.x = surface.m_areaDeClip.x;
			srcRect.y = surface.m_areaDeClip.y;
			srcRect.w = surface.m_areaDeClip.w;
			srcRect.h = surface.m_areaDeClip.h;

			Sdl.SDL_BlitSurface(surface.m_superficie, ref srcRect, m_superficie, ref dstRect);

			return true;
		}

		/// <summary>
		///  Dibuja la supericie dada en el punto (x, y) tomados desde el ancla
		/// </summary>
		/// <param name="surface">la superficie a dibujar</param>
		/// <param name="x">La posicion x</param>
		/// <param name="y">La posicion y</param>
		/// <param name="alpha">El canal alpha.</param>
		/// <param name="ancla">El ancla desde donde tomar el x, y</param>
		/// <returns>true si pudo dibujar</returns>
		unsafe public bool Dibujar(Superficie surface, short x, short y, byte alpha, short ancla)
		{
			Sdl.SDL_Rect dstRect;

			dstRect.x = x;
			dstRect.y = y;
			dstRect.h = dstRect.w = 0;

			Sdl.SDL_Rect srcRect;

			if ((ancla & Superficie.H_CENTRO) != 0)
			{
				dstRect.x += (short)(m_ancho / 2 - surface.m_ancho / 2);
			}

			if ((ancla & Superficie.V_CENTRO) != 0)
			{
				dstRect.y += (short)(m_alto / 2 - surface.m_alto / 2);
			}

			if ((ancla & Superficie.V_FONDO) != 0)
			{
				dstRect.y += (short)(m_alto - surface.m_alto);
			}

			srcRect.x = surface.m_areaDeClip.x;
			srcRect.y = surface.m_areaDeClip.y;
			srcRect.w = surface.m_areaDeClip.w;
			srcRect.h = surface.m_areaDeClip.h;

			Sdl.SDL_SetAlpha(surface.m_superficie, Sdl.SDL_SRCALPHA | Sdl.SDL_RLEACCEL, alpha);

			Sdl.SDL_BlitSurface(surface.m_superficie, ref srcRect, m_superficie, ref dstRect);

			Sdl.SDL_SetAlpha(surface.m_superficie, Sdl.SDL_SRCALPHA | Sdl.SDL_RLEACCEL, 255);

			return true;
        }

		 /// <summary>
        /// Escribe el string dado con la fuente seteada.
        /// <param name="str">El mensaje a escribir.</param>
        /// <param name="x">La posición x donde se comenzará a escribir.</param>
        /// <param name="y">La posición y donde se comenzará a escribir.</param>
        /// <param name="ancla">La posicion desde donde se va a tomar el punto (x, y). 
        /// 0 para que lo tome de la esquina superior izquierda, 
        /// Superficie.H_CENTER o Superficie.V_CENTER son también
        /// valores posibles</param>
        /// <returns>true -1 si no hubo éxito o el tamaño del tezto escrito. </returns>
		unsafe public int Escribir(int id, int x, int y, int ancla)
		{
			string str = Texto.Strings[id];
			return Escribir(str, x, y, ancla);
		}

        /// <summary>
        /// Escribe el string dado con la fuente seteada.
        /// <param name="str">El mensaje a escribir.</param>
        /// <param name="x">La posición x donde se comenzará a escribir.</param>
        /// <param name="y">La posición y donde se comenzará a escribir.</param>
        /// <param name="ancla">La posicion desde donde se va a tomar el punto (x, y). 
        /// 0 para que lo tome de la esquina superior izquierda, 
        /// Superficie.H_CENTER o Superficie.V_CENTER son también
        /// valores posibles</param>
        /// <returns>true -1 si no hubo éxito o el tamaño del tezto escrito. </returns>
        unsafe public int Escribir(string str, int x, int y, int ancla)

        {
			
            if (m_fuente == null)
            {

                Log.Instancia.Advertir("No se escribe el texto \"" + str + "\" porque no hay una fuente seteada.");
                return -1;
            }

			if (str == "")
			{
				return 0;
			}

			string  [] separador = {"\\n"};
			string[] renglones = str.Split(separador, StringSplitOptions.RemoveEmptyEntries);

			if (renglones.Length == 1)
			{
				return EscribirReglon(str, x, y, ancla);
			}
	
			IntPtr text = m_fuente.ObtenerTextoRenderizado(str);

			if (text == IntPtr.Zero)
			{
				return -1;
			}

			Sdl.SDL_Rect srcRect;

			srcRect = ((Sdl.SDL_Surface*)text.ToPointer())->clip_rect;

			int alto = srcRect.h;

			int espaciadoEntreLineas = 0;// Definiciones.ESPACIO_ENTRE_LINEAS;

			int maxAncho = -1;
			int ancho;

			int altoTotal = renglones.Length * (alto + espaciadoEntreLineas);

			if ((ancla & Superficie.V_CENTRO) != 0)
			{
				y -= altoTotal >> 1;
			}

			for (int i = 0; i < renglones.Length; i++)
			{
				ancho = EscribirReglon(renglones[i], x, y + i * (alto + espaciadoEntreLineas), ancla);
				if (ancho > maxAncho)
				{
					maxAncho = ancho;
				}
			}
			return maxAncho;
        }

		/// <summary>
		/// Escrible lo pasado por parametro en un solo reglon.
		/// </summary>
		/// <param name="str">El mensaje a escribir.</param>
		/// <param name="x">La posición x donde se comenzará a escribir.</param>
		/// <param name="y">La posición y donde se comenzará a escribir.</param>
		/// <param name="ancla">La posicion desde donde se va a tomar el punto (x, y). 
		/// 0 para que lo tome de la esquina superior izquierda, 
		/// Superficie.H_CENTER o Superficie.V_CENTER son también
		/// valores posibles</param>
		/// <returns>true -1 si no hubo éxito o el tamaño del tezto escrito. </returns>
		unsafe private int EscribirReglon(string str, int x, int y, int ancla)
		{
			if (m_fuente == null)
			{

				Log.Instancia.Advertir("No se escribe el texto \"" + str + "\" porque no hay una fuente seteada.");
				return -1;
			}

			if (str == "")
			{
				return 0;
			}

			IntPtr text = m_fuente.ObtenerTextoRenderizado(str);

			if (text == IntPtr.Zero)
			{
				return -1;
			}


			Sdl.SDL_Rect srcRect, dstRect;

			dstRect.x = (short)x;
			dstRect.y = (short)y;
			dstRect.w = dstRect.h = 0;

			srcRect = ((Sdl.SDL_Surface*)text.ToPointer())->clip_rect;

			if ((ancla & Superficie.H_CENTRO) != 0)
			{
				dstRect.x += (short)(m_ancho / 2 - srcRect.w / 2);
			}

			if ((ancla & Superficie.V_CENTRO) != 0)
			{
				dstRect.y += (short)(m_alto / 2 - srcRect.h / 2);
			}

			Sdl.SDL_BlitSurface(text, ref srcRect, m_superficie, ref dstRect);

			//Libero la Surface creada.
			Sdl.SDL_FreeSurface(text);

			return srcRect.w;
		}

        /// <summary>
        /// Averigua el color del pixel en el punto i, j de la superficie
        /// </summary>
        /// <param name="i">El punto i de la imagen </param>
        /// <param name="j"> El punto j de la imagen</param>
        /// <returns>El color del píxel en el punto i, j de la superficie</returns>
        unsafe public int ColorPixel(int x, int y)
        {
            if (x > m_ancho || y > m_alto || x < 0 || y < 0)
            {
                return -1;
            }

            Sdl.SDL_PixelFormat format = IntPtrAPixelFormat(((Sdl.SDL_Surface*)m_superficie.ToPointer())->format);
            int color = 0;

            if (format.BytesPerPixel == sizeof(int))
            {
                int* a = ((int*)(((Sdl.SDL_Surface*)m_superficie.ToPointer())->pixels.ToPointer()));
                color = a[x + y * m_ancho];
            }
            else if (format.BytesPerPixel == sizeof(short))
            {
                //TODO: Error! no anda bien si la imagen tiene un ancho impar... !!!
                short* a = ((short*)(((Sdl.SDL_Surface*)m_superficie.ToPointer())->pixels.ToPointer()));
                color = a[x + y * m_ancho] & 0xFFFF;

            }
            return color;
        }

        /// <summary>
        /// Devuelve el puntero converido en Sdl.SDL_PixelFormat.
        /// </summary>
        /// <param name="pixelFormat">El IntPtr a convertir.</param>
        /// <returns>La Sdl.Sdl_Surface que corresponde al puntero pasado por parámetro.</returns>
        unsafe protected Sdl.SDL_PixelFormat IntPtrAPixelFormat(IntPtr pixelFormatIntPtr)
        {
            Sdl.SDL_PixelFormat pixelFormat =
               (Sdl.SDL_PixelFormat)Marshal.PtrToStructure(pixelFormatIntPtr, typeof(Sdl.SDL_PixelFormat));
            return pixelFormat;
        }

        /// <summary>
        /// Devuelve el puntero converido en Sdl.SDL_Surface.
        /// </summary>
        /// <param name="surface">El IntPtr a convertir.</param>
        /// <returns>La Sdl.Sdl_Surface que corresponde al puntero pasado por parámetro.</returns>
        unsafe protected Sdl.SDL_Surface IntPtrASurface(IntPtr surface)
        {
            Sdl.SDL_Surface sdlSurface =
                (Sdl.SDL_Surface)Marshal.PtrToStructure(surface, typeof(Sdl.SDL_Surface));
            return sdlSurface;
        }

        /// <summary>
        /// Dibuja una linea recta.
        /// </summary>
        /// <param name="sX">El inicio x del punto.</param>
        /// <param name="sY">El inicio y del punto.</param>
        /// <param name="w">El ancho de la línea.</param>
        unsafe public void DibujarLinea(int sX, int sY, int w)
        {
            Sdl.SDL_Rect srcRect = new Sdl.SDL_Rect();
            srcRect.x = (short)(sX);
            srcRect.w = (short)(w);
            srcRect.y = (short)sY;
            srcRect.h = (short)1;
            Sdl.SDL_FillRect(m_superficie, ref srcRect, m_color);
        }
        #endregion

        public bool ImagenEstaCargada()
        {
            return m_superficie != IntPtr.Zero;
        }
    }
}