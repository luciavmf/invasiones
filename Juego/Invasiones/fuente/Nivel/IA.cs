using System;
using System.Collections.Generic;
using System.Text;
using Invasiones.Debug;
using System.Xml;
using Invasiones.Recursos;
using System.Drawing;

namespace Invasiones.Nivel
{
    /// <summary>
    /// Representa la inteligencia artificial de los grupos enemigas.
    /// </summary>
    public class IA
    {
        #region clase privada
        /// <summary>
        /// Contiene las ordenes que se tienen que cumplir en la batalla.
        /// </summary>
        private class Batalla
        {
            /// <summary>
            /// Este tipo de batallas solamente puede tener ordenes.
            /// </summary>
            public Stack<Orden> m_ordenes;

            /// <summary>
            /// Constructror.
            /// </summary>
            public Batalla()
            {
                m_ordenes = new Stack<Orden>();
            }
        }
        #endregion

        /// <summary>
        /// Las batallas posibles que puede tener el nivel.
        /// </summary>
        private Batalla[] m_batallas;

        /// <summary>
        /// La cantidad de batallas actuales.
        /// </summary>
        private int m_cantidadDeBatallas;

        /// <summary>
        /// el número de la batalla actual.
        /// </summary>
        private int m_nroBatallaActual;

        /// <summary>
        /// Constructor
        /// </summary>
        public IA()
        {
            m_batallas = new Batalla[Nivel.MAXIMA_CANTIDAD_BATALLAS];
            m_cantidadDeBatallas = 0;
        }

        /// <summary>
        /// Carga la inteligencia artificial.
        /// </summary>
        /// <param name="x"></param>
        /// <param name="y"></param>
        public void Cargar(int x, int y, int nroNivel)
        {
            string path = Utilidades.ObtenerPath(Programa.PATH_NIVEL + " \\orden_nv" + nroNivel + "_" + x + "_" + y + ".xml");

            if (path == null)
            {
                Log.Instancia.Debug("No se pueden cargar los objetivos. No se encuentra el archivo.");
            }
            m_cantidadDeBatallas = 0;

            XmlTextReader lector = new XmlTextReader(path);

            Orden ord;
            List<Orden> ordenes = new List<Orden>();

            try
            {
                while (lector.Read())
                {
                    if (lector.NodeType == XmlNodeType.Element && lector.Name == "batalla")
                    {
                        m_batallas[m_cantidadDeBatallas] = new Batalla();

                        while (lector.Read() && !(lector.NodeType == XmlNodeType.EndElement && lector.Name == "batalla"))
                        {
                            m_batallas[m_cantidadDeBatallas].m_ordenes = new Stack<Orden>();

                            if (lector.NodeType == XmlNodeType.Element)
                            {
                                Point punto = new Point();
                                Orden.TIPO id = Orden.TIPO.INVALIDA;

                                if (lector.Name == "llegar")
                                {
                                    id = Orden.TIPO.MOVER;
                                }

                                if (lector.Name == "patrullar")
                                {
                                    id = Orden.TIPO.PATRULLAR;
                                }

                                //multiplico las posiciones por dos apra quee sten medidas en tiles chicos.
                                lector.MoveToAttribute("i");
                                punto.X = Convert.ToInt16(lector.Value) << 1;

                                lector.MoveToAttribute("j");
                                punto.Y = Convert.ToInt16(lector.Value) << 1;

                                ord = new Orden(id, punto.X, punto.Y);
                                ordenes.Add(ord);
                            }
                        }
                        //termine de leer la batalla

                        //revierto las ordenes y las pongo en una pila.
                        for (int i = ordenes.Count - 1; i >= 0; i--)
                        {
                            m_batallas[m_cantidadDeBatallas].m_ordenes.Push(ordenes[i]);
                        }
                        ordenes = new List<Orden>();

                        m_cantidadDeBatallas++;
                    }
                }
            }
            catch (Exception e)
            {
                lector.Close();
                Log.Instancia.Error("Error al leer el archivo xml de la inteligencia artificial, exc: " + e.Message);
            }
            m_nroBatallaActual = 0;
            lector.Close();
        }

        /// <summary>
        /// Devuelve la proxima orden que tiene que se tiene que cumplir.
        /// </summary>
        /// <returns></returns>
        public Orden ProximaOrden()
        {
            if (m_nroBatallaActual >= m_cantidadDeBatallas)
            {
                Log.Instancia.Debug("No hay mas batallas que setear.");
                return null;
            }

            if (m_batallas[m_nroBatallaActual].m_ordenes.Count == 0)
            {
                Log.Instancia.Debug("Paso a la siguiente batalla, no hay mas ordenes que cumplir para esta batalla.");

                m_nroBatallaActual++;

                if (m_nroBatallaActual >= m_cantidadDeBatallas)
                {
                    Log.Instancia.Debug("No hay mas batallas que setear.");
                    return null;
                }

            }

            return m_batallas[m_nroBatallaActual].m_ordenes.Pop();
        }
    }
}
