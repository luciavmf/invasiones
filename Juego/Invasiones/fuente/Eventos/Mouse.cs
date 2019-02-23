using System;
using System.Collections.Generic;
using System.Text;
using System.Drawing;
using Invasiones.Debug;
using Tao.Sdl;
using Invasiones.Dibujo;
using Invasiones.Recursos;

namespace Invasiones.Eventos
{
    /// <summary>
    /// Clase que contiene todo lo necesrio para manejar eventos de entrada: Teclado j
    /// Mouse.
    /// </summary>
    public class Mouse
    {
        #region Declaraciones
        public const int BOTON_IZQ = Sdl.SDL_BUTTON_LEFT;
        public const int BOTON_CNT = Sdl.SDL_BUTTON_MIDDLE;
        public const int BOTON_DER = Sdl.SDL_BUTTON_RIGHT;

        /// <summary>
        /// La posición I a donde el mouse esta apuntando.
        /// </summary>
        private short m_x;

        /// <summary>
        /// La posición J a donde el mouse esta apuntando.
        /// </summary>
        private short m_y;

        /// <summary>
        /// Dice si el mouse esta siendo arrastrado.
        /// </summary>
        private bool m_arrastrando;

		/// <summary>
		/// La imagen del cursor a mostrar.
		/// </summary>
		private Superficie m_imagenCursor;

		/// <summary>
		/// Indica si el cursor esta oculto o no.
		/// </summary>
		private bool m_cursorOculto;

        /// <summary>
        /// Solo los boones apretados del mouse estan guardados aqui.
        /// </summary>
        private List<int> m_botonesDelMouseApretados;

        /// <summary>
        /// Posición de inicio de arrastre.
        /// </summary>
        private Point m_posicionInicioArrastre;

        /// <summary>
        /// La instancia de la clase.
        /// </summary>
        private static Mouse s_instancia;

        /// <summary>
        /// Contiene el rectángulo arrastrado.
        /// </summary>
        private Rectangle m_rectanguloArrastrado;
        
        /// <summary>
        /// Dice si termino de arrastrar recien o no.
        /// </summary>
        private bool m_terminoDeArrastrar;
        #endregion

        #region Properties
        /// <summary>
        /// Devuelve la instancia de la clase.
        /// </summary>
        public static Mouse Instancia
        {
            get
            {
                if (s_instancia == null)
                {
                    s_instancia = new Mouse();
                }
                return s_instancia;
            }
        }

        /// <summary>
        /// Devuelve una Lista con los botones del mouse apretados.
        /// </summary>
        public List<int> BotonesApretados
        {
            get
            {
                return m_botonesDelMouseApretados;
            }
        }

        /// <summary>
        /// Devuelve la posición i del mouse.
        /// </summary>
        public short X
        {
            get
            {
                return m_x;
            }
            set
            {
                if (value >= 0 && value < Video.Ancho)
                {
                    m_x = value;
                }
            }
        }

        /// <summary>
        /// Devuelve la posición j del mouse.
        /// </summary>
        public short Y
        {
            get
            {
                return m_y;
            }
            set
            {
                if (value >= 0 && value < Video.Alto)
                {
                    m_y = value;
                }
            }
        }

        /// <summary>
        /// Devuelve el rectángulo si es que esta siendo arrastrado el mouse.
        /// </summary>
        public Rectangle RectanguloArrastrado
        {
            get
            {
                return m_rectanguloArrastrado;
            }
        }
        #endregion

        #region Constructores
        /// <summary>
        /// Constructor de la clase. Privado para que haya solamente una instancia de la
        /// clase.
        /// </summary>
        private Mouse()
        {
            m_botonesDelMouseApretados = new List<int>();
            m_rectanguloArrastrado = new Rectangle();
            m_posicionInicioArrastre = new Point();
        }
        #endregion

        #region Metodos
        /// <summary>
        /// Chequea todos los eventos que ocurrieron y los guarda en los miembros privados
        /// de la clase.
        /// Chequea si el mouse esta siendo arrastrado.
        /// </summary>
        public void Actualizar()
        {
			//int timeAct = Sdl.SDL_GetTicks();
            if (m_botonesDelMouseApretados.Contains(Sdl.SDL_BUTTON_LEFT))
            {
                if (!m_arrastrando)
                {
                    m_arrastrando = true;
                    m_posicionInicioArrastre.X = m_x;
                    m_posicionInicioArrastre.Y = m_y;
                }
                else
                {
                    if (m_x > m_posicionInicioArrastre.X)
                    {
                        m_rectanguloArrastrado.Width = m_x - m_posicionInicioArrastre.X;
                        m_rectanguloArrastrado.X = m_posicionInicioArrastre.X;
                    }
                    else
                    {
                        m_rectanguloArrastrado.Width = m_posicionInicioArrastre.X - m_x;
                        m_rectanguloArrastrado.X = m_x;
                    }

                    if (m_y > m_posicionInicioArrastre.Y)
                    {
                        m_rectanguloArrastrado.Height = m_y - m_posicionInicioArrastre.Y;
                        m_rectanguloArrastrado.Y = m_posicionInicioArrastre.Y;
                    }
                    else
                    {
                        m_rectanguloArrastrado.Height = m_posicionInicioArrastre.Y - m_y;
                        m_rectanguloArrastrado.Y = m_y;
                    }
                }
            }
            else
            {
                m_terminoDeArrastrar = false;

                if (!m_arrastrando)
                {
                    m_rectanguloArrastrado.X = 0;
                    m_rectanguloArrastrado.Y = 0;
                    m_rectanguloArrastrado.Width = 0;
                    m_rectanguloArrastrado.Height = 0;
                }
                else 
                {
                    m_terminoDeArrastrar = true;
                }
                
                m_arrastrando = false;
            }
			//int timeDes = Sdl.SDL_GetTicks();

			//Log.Instancia.Debug("Mouse Actualizo: " + (timeDes - timeAct));
        }

        /// <summary>
        /// Auto explicativo.
        /// </summary>
        public bool Arrastrando()
        {
            return m_arrastrando;
        }

        /// <summary>
        /// Dice si justo se temrino de arrastrar o no.
        /// </summary>
        public bool TerminoDeArrastrar()
        {
            return m_terminoDeArrastrar;
        }

        /// <summary>
        /// Oculta el cursor de la pantalla
        /// </summary>
        public void OcultarCursor()
        {
            Sdl.SDL_ShowCursor(Sdl.SDL_DISABLE);
            m_cursorOculto = true;
        }

        /// <summary>
        /// Muestra el cursor en la pantalla
        /// </summary>
        public void MostrarCursor()
        {
            m_cursorOculto = false;
        }

        /// <summary>
        /// Carga las inmagenes de los cursores.
        /// </summary>
        public void SetearCursor(Superficie sup)
        {
            m_imagenCursor = sup;
        }

        /// <summary>
        /// Dibuja el cursor en pantalla.
        /// </summary>
        /// <param name="m_pantalla"></param>
        public void DibujarCursor(Video g)
        {
            if (m_cursorOculto)
            {
                return;
            }

            if (m_imagenCursor == null)
            {
                Sdl.SDL_ShowCursor(Sdl.SDL_ENABLE);
                Log.Instancia.Error("No se muestra el cursor porque no tiene ninguna imagen cargada aún.");
                return;
            }

            g.Dibujar(m_imagenCursor, m_x, m_y, 0);
        }

        /// <summary>
        /// Posiciona el cursor en el x, y dado.
        /// </summary>
        /// <param name="x"></param>
        /// <param name="y"></param>
        public void PosicionarCursor(int x, int y)
        {
            if (x < 0)
                x = 0;
            if (y < 0)
                y = 0;
            if (x > Video.Ancho)
                x = Video.Ancho;
            if (y > Video.Alto)
                y = Video.Alto;

            Sdl.SDL_WarpMouse((short)x, (short)y);
        }
        #endregion
	}
}