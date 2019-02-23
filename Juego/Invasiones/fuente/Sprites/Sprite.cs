using System;
using System.Collections.Generic;
using System.Text;
using Tao.Sdl;
using Invasiones.Debug;
using Invasiones.Dibujo;
using System.Collections;
using Invasiones.Recursos;
using System.Drawing;
using Invasiones.Map;

namespace Invasiones.Sprites
{
	/// <summary>
	/// Clase que contiene los sprites. Permite cargar, animar un sprite. Se trata de
	/// un tipo de m_mapa de bits dibujados en la pantalla de ordenador por  el hardware,
	/// sin cálculos adicionales de la CPU. Poseen transparencias, dejándoles así
	/// asumir otras formas a la del rectángulo.
	/// </summary>
	public class Sprite
	{

		/// <summary>
		/// Las animaciones que tiene el sprite.
		/// </summary>
		protected Animaciones[] m_animaciones;

		/// <summary>
		/// La animacion actual, la que esta reproduciendo en un instante dado.
		/// </summary>
		protected Animaciones m_animacionActual;

		/// <summary>
		/// El id de la animacion actual.
		/// </summary>
		private int m_idAnimacionActual;

		public Sprite()
		{
		}

		/// <summary>
		/// Constructor de copia del Sprite
		/// </summary>
		/// <param name="spr"> el Sprite que se quiere copiar.</param>
		public Sprite(ref Sprite spr)
		{
			m_animaciones = new Animaciones[spr.m_animaciones.Length];

			for (int i = 0; i < spr.m_animaciones.Length; i++)
			{
				m_animaciones[i] = new Animaciones(spr.m_animaciones[i]);
			}

			m_animacionActual = m_animaciones[0];
		}

		/// <summary>
		/// Destructor de la clase.
		/// </summary>
		~Sprite()
		{
			this.Dispose();
		}

		/// <summary>
		/// Libera cualquier recurso utilizado.
		/// </summary>
		public virtual void Dispose()
		{
			GC.SuppressFinalize(this);
		}

		/// <summary>
		/// Método abstracto a ser pisado por las clases derivadas. Actualiza el sprite.
		/// </summary>
		public void Actualizar()
		{
			m_animacionActual.Actualizar();
		}

		/// <summary>
		/// Setea true o false si la animacion loopea  o no. 
		/// </summary>
		public bool Loop
		{
			get { return m_animacionActual.Loop; }
			set { m_animacionActual.Loop = value; }
		}

		/// <summary>
		/// Setea la animación dada por parámetro en el frame 0.
		/// </summary>
		/// <param name="anim">el id de la animación</param>
		/// <returns>true si pudo cargar correctamente.</returns>
		public bool SetearAnimacion(int anim)
		{

			if (m_idAnimacionActual == anim)
			{
				return false;
			}
			m_idAnimacionActual = anim;

			int resta = 0;
			int animacionesAnteriores = 0;

			for (int i = 0; i < m_animaciones.Length; i++)
			{
				if (anim >= animacionesAnteriores && anim - animacionesAnteriores < m_animaciones[i].CantidadDeAnimaciones)
				{
					m_animacionActual = m_animaciones[i];
					resta = animacionesAnteriores;
				}
				animacionesAnteriores += m_animaciones[i].CantidadDeAnimaciones;
			}

			m_animacionActual.SetearAnimacion(anim - resta);

			return true;

		}

		/// <summary>
		/// Agrega animaciones a la clase. Es utilizada por la clase AdministradorDeUnidades
		/// </summary>
		/// <param name="i">El índice de la animación</param>
		/// <param name="anim">El objeto que contiene la información de la animación.</param>
		/// <returns>true si pudo agregar la animaciçon.</returns>
		public bool AgregarAnimacion(int i, Animaciones anim)
		{
			if (m_animaciones == null)
			{
				Log.Instancia.Error("No se carga la unidad porque no esta seteada la cantidad de animaciones que tiene el sprite.");
				return false;
			}

			if (i >= m_animaciones.Length)
			{
				Log.Instancia.Debug("La animacion qeu se quiere agregar tiene un indice inválido.");
				return false;
			}
			m_animaciones[i] = anim;
			return true;
		}


		/// <summary>
		/// Dibuja el sprite en la pantalla
		/// </summary>
		/// <param name="g">El Video en donde dibujarlo.</param>
		public void Dibujar(Video g, int x, int y)
		{
			g.Dibujar(m_animacionActual.Imagen, x, y, 0);
			//g.Dibujar(m_imagen, x, y, 0);
		}

		/// <summary>
		/// Carga la imagen asociada al sprite.
		/// </summary>
		public bool Cargar()
		{
			bool ok = true;
			for (int i = 0; i < m_animaciones.Length; i++)
			{
				if (!m_animaciones[i].Cargar())
				{
					ok = false;
				}
			}
			m_animacionActual = m_animaciones[0];

			return ok;
		}

		/// <summary>
		/// Las animaciones que contiene el Sprite.
		/// </summary>
		public Animaciones[] Animaciones
		{
			get { return m_animaciones; }
			set { m_animaciones = value; }
		}

		/// <summary>
		/// El ancho del frame.
		/// </summary>
		public int FrameAncho
		{
			get { return m_animacionActual.FrameAncho; }
		}

		/// <summary>
		/// El alto del frame.
		/// </summary>
		public int FrameAlto
		{
			get { return m_animacionActual.FrameAlto; }
		}


		public int CantidadDeFrames
		{
			get { return m_animacionActual.CantidadDeFrames; }
		}
		///<summary>
		///Devuelve la imagen del sprite.
		///</summary>
		public Superficie Imagen
		{
			get { return m_animacionActual.Imagen; }
		}

		/// <summary>
		///  Setea el sprite en estado reproduciendo.
		/// </summary>
		public void Reproducir()
		{
			m_animacionActual.Reproducir();
		}

		/// <summary>
		///  Setea el sprite en estado reproduciendo = false
		/// </summary>
		public void Parar()
		{
			m_animacionActual.Parar();
		}

		public Point Offsets
		{
			get { return m_animacionActual.Offsets; }
		}


		public bool TerminoDeAnimar()
		{
			return m_animacionActual.TerminoDeAnimar();
		}

		public int FrameActual
		{
			get
			{
				return m_animacionActual.FrameActual;
			}
		}

		public int AnimacionActual
		{
			get
			{
				return m_animacionActual.AnimacionActual;
			}
		}

		public void SetearFrame(int p)
		{
			if (m_animacionActual != null)
			{
				m_animacionActual.SetearFrame(p);
			}
		}
	}
}
