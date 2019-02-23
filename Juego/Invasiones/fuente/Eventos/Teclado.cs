using System;
using System.Collections.Generic;
using System.Text;
using Tao.Sdl;

namespace Invasiones.Eventos
{
    class Teclado
    {
        #region Declaraciones

		public const int INTERVALO_ENTRE_REPETICIONES = 15;

        public const int TECLA_ARR = Sdl.SDLK_UP;
        public const int TECLA_ABJ = Sdl.SDLK_DOWN;
        public const int TECLA_IZQ = Sdl.SDLK_LEFT;
        public const int TECLA_DER = Sdl.SDLK_RIGHT;

        public const int TECLA_A = Sdl.SDLK_a;
        public const int TECLA_B = Sdl.SDLK_b;
        public const int TECLA_C = Sdl.SDLK_c;
        public const int TECLA_D = Sdl.SDLK_d;
        public const int TECLA_E = Sdl.SDLK_e;
        public const int TECLA_F = Sdl.SDLK_f;
        public const int TECLA_G = Sdl.SDLK_g;
        public const int TECLA_H = Sdl.SDLK_h;
        public const int TECLA_I = Sdl.SDLK_i;
        public const int TECLA_J = Sdl.SDLK_j;
        public const int TECLA_K = Sdl.SDLK_k;
        public const int TECLA_L = Sdl.SDLK_l;
        public const int TECLA_M = Sdl.SDLK_m;
        public const int TECLA_N = Sdl.SDLK_n;
        public const int TECLA_O = Sdl.SDLK_o;
        public const int TECLA_P = Sdl.SDLK_p;
        public const int TECLA_Q = Sdl.SDLK_q;
        public const int TECLA_R = Sdl.SDLK_r;
        public const int TECLA_S = Sdl.SDLK_s;
        public const int TECLA_T = Sdl.SDLK_t;
        public const int TECLA_U = Sdl.SDLK_u;
        public const int TECLA_V = Sdl.SDLK_v;
        public const int TECLA_W = Sdl.SDLK_w;
        public const int TECLA_X = Sdl.SDLK_x;
        public const int TECLA_Y = Sdl.SDLK_y;
        public const int TECLA_Z = Sdl.SDLK_z;

		public const int TECLA_RSHIFT = Sdl.SDLK_RSHIFT;
		public const int TECLA_LSHIFT = Sdl.SDLK_LSHIFT;
		public const int TECLA_MAYUSCULA = Sdl.SDLK_CAPSLOCK;
		public const int TECLA_BACKSPACE = Sdl.SDLK_BACKSPACE;
		public const int TECLA_ENTER = Sdl.SDLK_RETURN;
		public const int TECLA_ESC = Sdl.SDLK_ESCAPE;

        /// <summary>
        /// Solo las teclas que estan siendo apretadas estan guardadas aqui.
        /// </summary>
        private List<int> m_teclasApretadas;

        /// <summary>
        /// La instancia del teclado
        /// </summary>
        private static Teclado s_instancia;
        #endregion

        #region Constructores
        /// <summary>
        /// Cosntructor.
        /// </summary>
        private Teclado()
        {
            m_teclasApretadas = new List<int>();
        }
        #endregion

        #region Properties
        /// <summary>
        /// Devuelve la instancia de la clase.
        /// </summary>
        public static Teclado Instancia
        {
            get
            {
                if (s_instancia == null)
                {
                    s_instancia = new Teclado();
                }
                return s_instancia;
            }
        }

        /// <summary>
        /// Devuelve una lista con las teclas apretadas.
        /// </summary>
        public List<int> TeclasApretadas
        {
            get
            {
                return m_teclasApretadas;
            }
        }
        #endregion
    }
}