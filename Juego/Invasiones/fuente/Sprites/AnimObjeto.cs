using System;
using System.Collections.Generic;
using System.Text;
using Invasiones.Nivel;
using Invasiones.Sprites;
using Invasiones.Dibujo;
using System.Drawing;

namespace Invasiones.Sprites
{
    public class AnimObjeto : Objeto
    {
        private Animaciones m_animacion;

        public Animaciones Animacion
        {
            get
            {
                return m_animacion;
            }
        }

        public AnimObjeto(Animaciones anim, int i, int j)
        {
            m_posEnTileFisico.X = i;
            m_posEnTileFisico.Y = j;

            Point p = TransformarIJEnXY(m_posEnTileFisico.X, m_posEnTileFisico.Y);

            m_posEnMundoPlano.X = p.X;
            m_posEnMundoPlano.Y = p.Y;





            m_animacion = anim;
            m_animacion.Cargar();
            ActualizarPosicionXY();

            m_posEnMundoPlano.X -= m_animacion.Offsets.X;
            m_posEnMundoPlano.Y -= m_animacion.Offsets.Y;

            m_animacion.Reproducir();
            m_animacion.Loop = true;
        }

        public override void Actualizar()
        {
            base.Actualizar();

            m_animacion.Actualizar();
        }


        public override void Dibujar(Video g)
        {
            if (m_animacion != null)
            {
                if (m_posEnMundoPlano.X == -1 || m_posEnMundoPlano.Y == -1)
                {
                    return;
                }
                m_animacion.Dibujar(g, m_x + s_mapa.TileAncho / 2, m_y + s_mapa.TileAlto / 2, 0);
            }
        }

        public void SetearAnimacion(int anim)
        {
            m_animacion.SetearAnimacion(anim);
        }

        public void SetearPosicion(int i, int j)
        {
            m_posEnTileFisico.X = i;
            m_posEnTileFisico.Y = j;

            Point p = TransformarIJEnXY(m_posEnTileFisico.X, m_posEnTileFisico.Y);

            m_posEnMundoPlano.X = p.X;
            m_posEnMundoPlano.Y = p.Y;

            m_posEnMundoPlano.X -= m_animacion.Offsets.X;
            m_posEnMundoPlano.Y -= m_animacion.Offsets.Y;

            ActualizarPosicionXY();
        }

    }
}
