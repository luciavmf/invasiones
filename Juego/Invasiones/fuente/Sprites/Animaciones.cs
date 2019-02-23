using System;
using System.Collections.Generic;
using System.Text;
using Invasiones.Recursos;
using Invasiones.Debug;
using Invasiones.Dibujo;
using System.Drawing;

namespace Invasiones.Sprites
{
    public class Animaciones
    {
        #region Declaraciones

        /// <summary>
        /// El número de la animación actual.
        /// Tener en cuenta que una imagen se divide de la siguiente manera:
        /// 
        ///  frame frame
        ///    0     1
        ///  ----- -----
        /// |     |     |
        /// |     |     |
        /// |     |     |   <-- Animación 0
        /// |-----|-----|
        /// |     |     |   
        /// |     |     |
        /// |     |     |   <-- Animación 1
        ///  ----- -----
        ///  Para las animaciones este valor siempre es 0
        /// </summary>
        protected int m_animacionActual;

        /// <summary>
        /// El path de la imagen que lo contiene
        /// </summary>
        private string m_pathImagen;

        /// <summary>
        /// En ancho del frame
        /// </summary>
        protected short m_frameAncho;

        /// <summary>
        /// Dice si la animacion termino de reproducirse o no.
        /// </summary>
        protected bool m_animacionTerminada;

        /// <summary>
        /// Los offsets de la animacion. Indican desde que punto se tienen que pintar.
        /// </summary>
        protected Point m_offsets;

        /// <summary>
        /// El alto del frame
        /// </summary>
        protected short m_frameAlto;

        /// <summary>
        ///  La cantidad de ticks del frame
        /// </summary>
        protected short m_ticks;

        /// <summary>
        /// La cantidad de frames de la imagen
        /// </summary>
        protected short m_cantidadFrames;
        
        /// <summary>
        /// La cantidad de animaciones que tiene.
        /// </summary>
        protected short m_cantidadAnimaciones;

        /// <summary>
        /// Me dice si la animacion loopea o no.
        /// </summary>
        public bool Loop;

        /// <summary>
        /// Me dice si la animación esta cargada o no.
        /// </summary>
        private bool m_animacionCargada;

        /// <summary>
        /// Me dice si la animación fue leida o no.
        /// </summary>
        private bool m_animacionLeida;

        /// <summary>
        /// La cuenta actual de tick
        /// </summary>
        protected short m_ticksActuales;

        /// <summary>
        /// El frame actual a dibujar
        /// </summary>
        protected int m_frameActual;

        /// <summary>
        /// La imagen a dibujar
        /// </summary>
        protected Superficie m_imagen;

        /// <summary>
        /// Si la animacion se esta reproduciendo o no.
        /// </summary>
        protected bool m_reproduciendo;
        #endregion

        #region Properties
        public int AnimacionActual
        {
            get
            {
                return m_animacionActual;
            }
        }

        public short FrameAncho
        {
            get
            {
                return m_frameAncho;
            }
        }

        public short FrameAlto
        {
            get
            {
                return m_frameAlto;
            }
        }

        public Point Offsets
        {
            get
            {
                return m_offsets;
            }
        }

        public short CantidadDeFrames
        {
            get
            {
                return m_cantidadFrames;
            }
        }

        /// <summary>
        /// El frame actual.
        /// </summary>
        public int FrameActual
        {
            get
            {
                return m_frameActual;
            }
        }

        public Superficie Imagen
        {
            get
            {
                return m_imagen;
            }
        }

        public short CantidadDeAnimaciones
        {
            get
            {
                return m_cantidadAnimaciones;
            }
        }

        /// <summary>
        /// Setea la animacion actual.
        /// </summary>
        /// <param name="anim"></param>
        /// <returns></returns>
        public bool SetearAnimacion(int anim)
        {
            if (anim == m_animacionActual)
            {
                return false;
            }
            if (anim < 0 || anim > m_cantidadAnimaciones)
            {
                return false;
            }

            m_animacionActual = anim;

            //seteo en el frame 0
            m_frameActual = 0;
            m_imagen.SetearClip(m_frameActual * m_frameAncho, m_animacionActual * m_frameAlto, m_frameAncho, m_frameAlto);

            m_animacionTerminada = false;
            return true;
        }
        #endregion

        #region Metodos
        /// <summary>
        /// Constructor. Por defecto, se tiene que crear una animación con algún tipo de información.
        /// </summary>
        /// <param name="Id">el Id</param>
        /// <param name="path">el path de la imagen</param>
        /// <param name="frameAncho">el ancho del frame d</param>
        /// <param name="Ticks">la cantidad de Ticks hasta pasar al proximo frame</param>
        public Animaciones(short id, string path, short frameAncho, short ticks, Point offsets)
        {
            if (id < 0 || id > Res.ANIM_COUNT)
            {
                m_animacionLeida = false;
                return;
            }

            m_animacionActual = id;
            m_pathImagen = path;

            m_frameAncho = frameAncho;

            m_ticks = ticks;
            m_ticksActuales = 0;
            m_frameActual = 0;
            Loop = true;
            m_animacionLeida = true;
            m_offsets = offsets;

        }

        /// <summary>
        /// Constructor de copia.
        /// </summary>
        public Animaciones(Animaciones anim)
        {
            m_pathImagen = anim.m_pathImagen;
            m_ticks = anim.m_ticks;
            m_frameAlto = anim.m_frameAlto;
            m_frameAncho = anim.m_frameAncho;
            m_cantidadFrames = anim.m_cantidadFrames;
            m_cantidadAnimaciones = anim.m_cantidadAnimaciones;

            m_imagen = AdministradorDeRecursos.Instancia.ObtenerCopiaImagen(m_pathImagen);
            Loop = anim.Loop;

            m_offsets = anim.m_offsets;

            m_ticksActuales = 0;
            m_animacionActual = -1;

            SetearAnimacion(0);
        }

        /// <summary>
        /// Constructor. Por defecto, se tiene que crear una animación con algún tipo de información.
        /// </summary>
        /// <param name="idx">el indice de la animacion (o el alto en y donde empieza el cuadro)</param>
        /// <param name="nombreDelArchivo">el path de la imagen</param>
        /// <param name="Ticks">la cantidad de Ticks hasta pasar al proximo frame</param>
        /// <param name="anchoDelFrame">El ancho del frame</param>
        /// <param name="altoDelFrame">El alto del frame</param>
        public Animaciones(short idx, string nombreDelArchivo, short ticks, short anchoDelFrame, short altoDelFrame, Point offsets)
        {
            m_animacionActual = idx;

            m_pathImagen = nombreDelArchivo;
            m_ticks = ticks;
            m_frameAncho = anchoDelFrame;
            m_frameAlto = altoDelFrame;

            m_ticksActuales = 0;
            m_frameActual = 0;
            Loop = true;
            m_animacionLeida = true;

            m_offsets = offsets;
        }

        /// <summary>
        /// Carga la imagen de la animación pasada por parámetro.
        /// </summary>
        /// <returns>true si pudo cargar con éxito.</returns>
        public bool Cargar()
        {
            if (!m_animacionLeida)
            {
                Log.Instancia.Advertir("No se puede cargar la animacion " + m_animacionActual + ". La animación no fue leída aún.");
                return false;
            }
            if (m_animacionCargada)
            {
                Log.Instancia.Advertir("La animacion " + m_animacionActual + " ya fue cargada.");
                return false;
            }

            //Chequeo que no este cargada de antes!, si estaba cargada no la vargo otra vez.
            if (m_imagen == null)
            {
                m_imagen = AdministradorDeRecursos.Instancia.ObtenerImagen(m_pathImagen);
            }

            if (m_imagen == null)
            {
                m_animacionCargada = false;
                return false;
            }

            m_animacionCargada = true;
            if (m_frameAncho == 0)
            {
                m_frameAncho = m_imagen.Ancho;
            }
            if (m_frameAlto == 0)
            {
                m_frameAlto = m_imagen.Alto;
            }
            m_cantidadFrames = (short)(m_imagen.Ancho / m_frameAncho);
            m_cantidadAnimaciones = (short)(m_imagen.Alto / m_frameAlto);

            m_imagen.SetearClip(0, (m_animacionActual * m_frameAlto), m_frameAncho, m_frameAlto);

            return true;
        }

        public void Parar()
        {
            m_reproduciendo = false;
        }

        public void Reproducir()
        {
            m_reproduciendo = true;
        }

        public bool TerminoDeAnimar()
        {
            return m_animacionTerminada;
        }

        public void SetearFrame(int p)
        {
            if (p >= 0 && p < m_cantidadFrames)
            {
                m_frameActual = p;
                m_imagen.SetearClip(m_frameActual * m_frameAncho, m_animacionActual * m_frameAlto, m_frameAncho, m_frameAlto);
            }
        }
        #endregion

        #region Metodos Virtuales
        /// <summary>
        /// Actualiza la animacion: en cada actualización incrementa los ticks de la animacion, si loopea
        /// cuando llega a la ultima pone en 0 el frame a reproducir.
        /// Va incrementando los m_ticksActuales en 1 hasta m_ticks;
        /// </summary>
        public virtual void Actualizar()
        {
            if (m_reproduciendo)
            {
                if (m_ticksActuales++ >= m_ticks)
                {
                    if (m_frameActual >= m_cantidadFrames)
                    {
                        if (Loop)
                        {
                            m_frameActual = 0;
                        }
                        else
                        {
                            m_reproduciendo = false;
                            m_animacionTerminada = true;
                        }
                    }
                    m_imagen.SetearClip(m_frameActual * m_frameAncho, m_animacionActual * m_frameAlto, m_frameAncho, m_frameAlto);

                    m_frameActual++;
                    m_ticksActuales = 0;
                }
            }
        }

        /// <summary>
        /// Dibuja el frame actual.
        /// </summary>
        /// <param name="g">el Video en donde pintar la animación.</param>
        /// <param name="i">el punto i en donde pintarla</param>
        /// <param name="j">el punto j en donde pintarla</param>
        /// <param name="ancla">el ancla desde dónde tomar el punto (i, j)</param>
        public virtual void Dibujar(Video g, int x, int y, short ancla)
        {
            if ((ancla & Superficie.V_CENTRO) != 0)
            {
                y  += Video.Alto / 2 -  m_frameAlto  / 2;
            }

            if ((ancla & Superficie.H_CENTRO) != 0)
            {
                x += Video.Ancho / 2 -  m_frameAncho / 2;
            }

            g.Dibujar(m_imagen, x, y, 0);
        }
        #endregion
    }
}