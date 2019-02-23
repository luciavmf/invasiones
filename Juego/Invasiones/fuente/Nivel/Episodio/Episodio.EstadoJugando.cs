using System;
using System.Collections.Generic;
using System.Text;
using Invasiones.Dibujo;
using Invasiones.Recursos;
using Invasiones.Eventos;
using System.Drawing;
using Invasiones.Nivel.Unidades;
using Invasiones.Debug;
using Invasiones.GUI;

namespace Invasiones.Nivel
{
    public partial class Episodio
    {
        int m_cheatGanarIndice = 0;
        int m_cheatPerderIndice = 0;
        int m_cheatObjetivoIndice = 0;


        public void chequearCheats()
        {
            if (Teclado.Instancia.TeclasApretadas.Contains(Teclado.TECLA_G) && m_cheatGanarIndice == 0)
            {
                m_cheatGanarIndice++;
            }
            else if (Teclado.Instancia.TeclasApretadas.Contains(Teclado.TECLA_A) && m_cheatGanarIndice == 1)
            {
                m_cheatGanarIndice++;
            }
            else if (Teclado.Instancia.TeclasApretadas.Contains(Teclado.TECLA_N) && m_cheatGanarIndice == 2)
            {
                m_cheatGanarIndice++;
            }
            else if (Teclado.Instancia.TeclasApretadas.Contains(Teclado.TECLA_X) && m_cheatGanarIndice == 3)
            {
                m_cheatGanarIndice++;
            }
            else if (Teclado.Instancia.TeclasApretadas.Contains(Teclado.TECLA_W) && m_cheatGanarIndice == 4)
            {
                m_cheatGanarIndice++;
                SetearEstado(ESTADO.GANO);
                m_cheatGanarIndice = 0;
            }
            else if (Teclado.Instancia.TeclasApretadas.Contains(Teclado.TECLA_P) && m_cheatPerderIndice == 0)
            {
                m_cheatPerderIndice++;
            }
            else if (Teclado.Instancia.TeclasApretadas.Contains(Teclado.TECLA_E) && m_cheatPerderIndice == 1)
            {
                m_cheatPerderIndice++;
            }
            else if (Teclado.Instancia.TeclasApretadas.Contains(Teclado.TECLA_R) && m_cheatPerderIndice == 2)
            {
                m_cheatPerderIndice++;
            }
            else if (Teclado.Instancia.TeclasApretadas.Contains(Teclado.TECLA_X) && m_cheatPerderIndice == 3)
            {
                m_cheatPerderIndice++;
            }
            else if (Teclado.Instancia.TeclasApretadas.Contains(Teclado.TECLA_W) && m_cheatPerderIndice == 4)
            {
                m_cheatPerderIndice++;
                SetearEstado(ESTADO.PERDIO);
                m_cheatPerderIndice = 0;
            }
            else if (Teclado.Instancia.TeclasApretadas.Contains(Teclado.TECLA_O) && m_cheatObjetivoIndice ==0)
            {
                m_cheatObjetivoIndice++;
            }
            else if (Teclado.Instancia.TeclasApretadas.Contains(Teclado.TECLA_B) && m_cheatObjetivoIndice == 1)
            {
                m_cheatObjetivoIndice++;
            }
            else if (Teclado.Instancia.TeclasApretadas.Contains(Teclado.TECLA_J) && m_cheatObjetivoIndice == 2)
            {
                m_cheatObjetivoIndice++;
            }
            else if (Teclado.Instancia.TeclasApretadas.Contains(Teclado.TECLA_X) && m_cheatObjetivoIndice == 3)
            {
                m_cheatObjetivoIndice++;
            }
            else if (Teclado.Instancia.TeclasApretadas.Contains(Teclado.TECLA_W) && m_cheatObjetivoIndice == 4)
            {
                m_cheatObjetivoIndice++;
                SetearNuevoObjetivo();
            }
            else if (Teclado.Instancia.TeclasApretadas.Count !=0)
            {
                if (Teclado.Instancia.TeclasApretadas.Contains(Teclado.TECLA_U))
                {
                    m_jugador.SeleccionarUnidadSiguiente();
                }
                Log.Instancia.Debug("Reseteo todos los cheats--");
                m_cheatObjetivoIndice = 0;
                m_cheatGanarIndice = 0;
                m_cheatPerderIndice = 0;
            }
            Teclado.Instancia.TeclasApretadas.Clear();
        }

        /// <summary>
        /// Actuliza el estado cargando de la batalla.
        /// </summary>
        private void ActualizarEstadoJugando()
        {

            if (m_mostrarPopupObjetivo)
            {
                m_cuentaMostrarObjetivo++;
            }

            if (Definiciones.CHEATS_HABILITADOS)
            {
                chequearCheats();
            }

            //Primero siempre se tiene que actualizar el mapa (porque se actualiza la posicion de la camara aca)
            m_mapa.Actualizar();

            m_mapa.CapaTilesVisibles = new short[m_mapa.AltoMapaFisico, m_mapa.AnchoMapaFisico];

            //Actualizo al jugador
            m_jugador.Actualizar();

            //Actualizo al enemigo
            m_enemigo.Actualizar();

            m_hud.CantidadArgentinos = m_jugador.CantidadDeUnidades;
            m_hud.CantidadEnemigos = m_enemigo.CantidadDeUnidades;

            ChequearFinDeJuego();

            //Actualizo el estado del HUD
            m_hud.Actualizar();

            ActualizarOrdenes();

            //Actualizo los objetos, se tiene que actualizar la posicion en donde van a ser pintados.
            foreach (Obstaculo obs in m_obstaculos)
            {
                obs.Actualizar();
            }
        }



        public void ChequearFinDeJuego()
        {
            if (m_jugador.CantidadDeUnidades == 0)
            {
                SetearEstado(ESTADO.PERDIO);
            }
        }

        /// <summary>
        /// Dibuja todos los objetos del juego: Mapa, Objetos, Unidades,
        /// Capa semitransparente, Hud...
        /// </summary>
        /// <param name="g">El Video en donde pintar.</param>
        private void DibujarEstadoJugando(Video g)
        {

            m_mapaTilesVisibles = new short[m_mapa.AltoMapaFisico, m_mapa.AnchoMapaFisico];

            //Limpo la pantalla
            g.LlenarRectangulo(Definiciones.COLOR_NEGRO);

            //Dibujo el mapa.
            m_mapa.DibujarCapa(g, m_mapa.CAPA_TERRENO);

            //Dibujo las unidades y los objetos (edificios, arboles, etc..
            //Los tiles de visibilidad tambien.)
            DibujarObjetos(g);

#if DEBUG
            //Dibujo la información de debug del m_mapa
            m_mapa.DibujarCapaInfo(g);

#endif
            DibujarCapaSemitransparente(g);

            //Dibujo el Hud
            m_hud.Dibujar(g);




            m_jugador.DibujarFlechaOrientacion(g);


            //Dibujo los objetivos.
            if (m_mostrarPopupObjetivo && m_cuentaMostrarObjetivo > Definiciones.CUENTA_MOSTRAR_OBJETIVO_INICIO)
            {
                SetearEstado(ESTADO.MOSTRAR_OBJETIVOS);
            }
            else if (m_mostrarRecordatorioObjetivo && m_cuentaMostrarObjetivo > Definiciones.CUENTA_MOSTRAR_OBJETIVO_INICIO)
            {
                g.SetearFuente(AdministradorDeRecursos.Instancia.Fuentes[Definiciones.FUENTE_RECORDATORIO_OBJETIVOS], Definiciones.COLOR_FUENTE_OBJETIVOS);
                g.Escribir(Res.STR_OBJETIVOS, Definiciones.OFFSET_OBJETIVOS << 1, m_camara.Alto - (Definiciones.ALTO_OBJETIVOS + Definiciones.OFFSET_OBJETIVOS * 2) - 10, 0);
                g.Escribir(Res.STR_OBJETIVO_BATALLA_1_1 + m_nivelActual.CantidadDeObjetivosCumplidos, Definiciones.OFFSET_OBJETIVOS << 1, m_camara.Alto - (Definiciones.ALTO_OBJETIVOS + Definiciones.OFFSET_OBJETIVOS * 2) + 5, 0);
            }


            // Dibujo el mouse en la pantalla
            if (Mouse.Instancia.Arrastrando())
            {
                //Dibujo el rectangulo de seleccion.
                g.SetearColor(Definiciones.COLOR_VERDE);

                g.DibujarRectangulo(Mouse.Instancia.RectanguloArrastrado.X, Mouse.Instancia.RectanguloArrastrado.Y,
                    Mouse.Instancia.RectanguloArrastrado.Width, Mouse.Instancia.RectanguloArrastrado.Height, 0);
            }
        }

        /// <summary>
        /// Dibuja la capa semitransparente que representa a posiciones del mapa no visibles.
        /// </summary>
        /// <param name="g">La referencia al Video.</param>
        private void DibujarCapaSemitransparente(Video g)
        {

            if (m_mapa.CapaTilesVisibles == null)
            {
                return;
            }

            Rectangle oldClip = g.ObtenerClip();

            g.SetearClip(m_camara.InicioX, m_camara.InicioY, m_camara.Ancho, m_camara.Alto);

            bool cambio = true;
            Rectangle rect = m_jugador.ObtenerCoordenadasDePintado();

            int XX = rect.X;
            int YY = rect.Y;

            int finI = rect.Width;
            int finJ = rect.Height;

            int tileY = 0;
            cambio = true;
            int tileX = 0;

            while (tileY <= finJ)
            {
                for (int i = XX, j = YY; tileX <= finI && j >= 0; i++, j--)
                {
                    if (i < m_mapa.AltoMapaFisico && i >= 0 && j < m_mapa.AnchoMapaFisico && j >= 0)
                    {
                        if (m_mapa.CapaTilesVisibles[i, j] == 0)
                        {
                            m_mapa.DibujarTileChico(g, i, j, true);
                        }
                    }
                    tileX++;
                }

                tileX = 0;
                tileY++;

                if (cambio == true)
                {
                    XX++;
                    cambio = false;
                }
                else
                {
                    cambio = true;
                    YY++;
                }
            }

            g.SetearClip(oldClip.X, oldClip.Y, oldClip.Width, oldClip.Height);

        }

        /// <summary>
        /// Dibuja los objetos en el mapa.
        /// </summary>
        /// <param name="g">La referencia al Video en donde pintar.</param>
        private void DibujarObjetos(Video g)
        {
            Rectangle oldClip = g.ObtenerClip();

            g.SetearClip(m_camara.InicioX, m_camara.InicioY, m_camara.Ancho, m_camara.Alto);

            bool cambio = true;

            Rectangle rect = m_jugador.ObtenerCoordenadasDePintado();

            int XX = rect.X;
            int YY = rect.Y;

            int tileX = 0;
            int tileY = 0;

            int finI = rect.Width;
            int finJ = rect.Height;

            while (tileY <= finJ)
            {
                for (int i = XX, j = YY; tileX <= finI && j >= 0; i++, j--)
                {
                    if (i < m_mapa.AltoMapaFisico && i >= 0 && j < m_mapa.AnchoMapaFisico && j >= 0)
                    {
                        if (m_objetosAPintar[i, j] != null)
                        {
                            if (m_objetosAPintar[i, j] is Unidad)
                            {
                                Unidad uni = (Unidad)(m_objetosAPintar[i, j]);
                                uni.Dibujar(g);
                            }

                            if (m_objetosAPintar[i, j] is Obstaculo)
                            {
                                Obstaculo obs = (Obstaculo)(m_objetosAPintar[i, j]);
                                obs.Dibujar(g);
                            }
                        }
                    }
                    tileX++;
                }

                tileX = 0;
                tileY++;

                if (cambio == true)
                {
                    XX++;
                    cambio = false;
                }
                else
                {
                    cambio = true;
                    YY++;
                }
            }

            m_jugador.Dibujar(g);
            g.SetearClip(oldClip.X, oldClip.Y, oldClip.Width, oldClip.Height);
        }

        /// <summary>
        /// Chequea si cumplio las ordenes, y si es asi setea una nueva.
        /// </summary>
        private void ActualizarOrdenes()
        {
            if (m_jugador.CumplioObjetivo())
            {
                Log.Instancia.Debug("Felicitaciones!! cumpliste el objetivo.....");
                SetearNuevoObjetivo();
            }
        }


    }
}
