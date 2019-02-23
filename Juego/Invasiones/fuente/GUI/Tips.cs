using System;
using System.Collections.Generic;
using System.Text;
using Invasiones.Dibujo;
using Invasiones.Recursos;
using Invasiones.Eventos;
using Invasiones.Debug;

namespace Invasiones.GUI
{
    class Tips : CajaGUI
    {
        // Boton de tips:
        private Boton m_botonTip;

        //boleano para saber si hay tip o no:
        private bool m_correspondeMostrarTip = false;

        private int m_cuentaTip;
        private const int INITIAL_TIP_TIME = 250;


        /// <summary>
        /// Las posibles selecciones dentro del menu.
        /// </summary>
        public enum SELECCION
        {
            NINGUNO = -1,
            IZQUIERDO,
            DERECHO
        }

        /// <summary>
        /// Costructor.
        /// </summary>
        /// <param name="leyenda">EL título que va a tener el menú de confirmación.</param>
        /// <param name="boton1">El título del boton izquierdo.</param>
        /// <param name="boton2">El título del boton derecho.</param>
        public Tips()
        {
            //m_leyenda = 1;
            m_botonTip = new Boton(Res.STR_TIP_00, null);

            m_botonTip.SetearPosicion(Video.Ancho - m_botonTip.Ancho - 20, Video.Alto - 90 - m_botonTip.Alto, 0);

            m_ancho = Definiciones.TIPS_ANCHO;
            m_alto = Definiciones.TIPS_ALTO;
            m_random = new Random();
            GenerarTipRandom();

            m_cuentaTip = INITIAL_TIP_TIME;
            m_correspondeMostrarTip = false;
        }

        Random m_random;
        /// <summary>
        /// Setea la posicion en donde se va a pintar el menú.
        /// </summary>
        /// <param name="x">Posición x.</param>
        /// <param name="y">Posición y.</param>
        /// <param name="ancla">El ancla de donde tomar el x, y</param>
        public override void SetearPosicion(int x, int y, int ancla)
        {
            m_x = x;
            m_y = y;
            if ((ancla & Superficie.H_CENTRO) != 0)
            {
                m_x += (Video.Ancho >> 1) - (m_ancho >> 1);
            }

            if ((ancla & Superficie.V_CENTRO) != 0)
            {
                m_y += (Video.Alto >> 1) - (m_alto >> 1);
            }

        }


        public byte m_alpha = 100;
        public byte ALPHA
        {
            set
            {
                m_alpha = value;
            }

        }

        private int m_cuentaTitila;

        private const int MAX_TITILA = 40;

        private const int MIN_TITILA = 20;


        /// <summary>
        /// Dibuja el boton.
        /// </summary>
        /// <param name="g">El Video en donde pintar.</param>
        public override void Dibujar(Video g)
        {
            if (!m_correspondeMostrarTip)
            {
                return;
            }

            if (m_botonTip.DebajoDelPuntero)
            {
                g.SetearColor(Definiciones.GUI_COLOR_MENUS);
                g.LlenarRectangulo(m_x, m_y, m_ancho, m_alto, m_alpha, 0);
                g.SetearFuente(AdministradorDeRecursos.Instancia.Fuentes[Definiciones.FUENTE_RECORDATORIO_OBJETIVOS], Definiciones.GUI_COLOR_TEXTO);
                g.Escribir(m_leyenda, m_x - (Video.Ancho >> 1) + (m_ancho >> 1), m_y + m_alto / 5, Superficie.H_CENTRO);
                m_botonTip.Dibujar(g);
                return;
            }
            else
            {
                m_cuentaTip--;
            }


            if (m_cuentaTitila > MIN_TITILA && m_cuentaTitila < MAX_TITILA)
            {
                m_botonTip.Dibujar(g);
                Log.Instancia.Debug("Bla ba bas muestro tip");
            }
        }

        public void GenerarTipRandom()
        {
            m_leyenda = m_random.Next(Res.STR_TIP_01, Res.STR_TIP_23);
      
        }

        /// <summary>
        /// Actualiza el menú.
        /// </summary>
        /// <returns>SELECCION.IZQUIERDO si se apreto el botón izquierdo, 
        /// SELECCION.DERECHO si se apreto el botón derecho, 
        /// SELECCION.NINGUNO si no se apreto ningun botón. </returns>
        public override int Actualizar()
        {
            m_cuentaTitila++;

            if (m_correspondeMostrarTip)
            {

                if (m_cuentaTip <= 0)
                {
                    m_correspondeMostrarTip = false;
                }

                if (m_cuentaTitila > MAX_TITILA)
                {
                    m_cuentaTitila = 0;
                }
            }
            else
            {
                if (m_random.Next(0, 300) == 99)
                {
                    m_correspondeMostrarTip = true;
                    m_cuentaTitila = 0;
                    m_cuentaTip = INITIAL_TIP_TIME;
                    GenerarTipRandom();
                }
            }

            m_botonTip.Actualizar();
            return (int)SELECCION.NINGUNO;
        }
    }
}