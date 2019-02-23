using System;
using System.Collections.Generic;
using System.Text;
using System.Xml;
using Invasiones.Debug;
using Invasiones.Recursos;
using System.Drawing;
using Invasiones.Sprites;

namespace Invasiones.Nivel
{
    public class Nivel
    {

        /// <summary>
        /// La cantidad máxima de batallas que puede haber.
        /// </summary>
        public const int MAXIMA_CANTIDAD_BATALLAS = 5;


        #region Clase privada
        /// <summary>
        /// Contiene una pila de objetivos a cumplir
        /// </summary>
        private class Batalla
        {
            /// <summary>
            /// Los objetivos de la batalla
            /// </summary>
            public Stack<Objetivo> m_objetivos;

            /// <summary>
            /// La cantidad de objetivos que tiene originalmente la batalla.
            /// </summary>
            public int CantidadDeObjetivos;

            /// <summary>
            /// cocstructor
            /// </summary>
            public Batalla()
            {
                m_objetivos = new Stack<Objetivo>();
            }
        }
        #endregion

        /// <summary>
        /// Contienen todas las batallas contenidas en el nivel.
        /// </summary>
        private Batalla[] m_batallas;

        /// <summary>
        /// La btala actual
        /// </summary>
        private int m_nroBatallaActual;

        /// <summary>
        /// La cantidad de objetivos que se cumplieron hasta ahora.
        /// </summary>
        private int m_cantidadeDeObjetivosCumplidos;

        /// <summary>
        /// Constructor.
        /// </summary>
        public Nivel()
        {
            m_batallas = new Batalla[MAXIMA_CANTIDAD_BATALLAS];
            m_nroBatallaActual = 0;
            m_cantidadDeBatallas = 0;
            m_cantidadeDeObjetivosCumplidos = -1;
        }

        /// <summary>
        /// El objetivo actual a seguir.
        /// <summary>
        private int m_nroObjetivoActual;

        /// <summary>
        /// La cantidad de batallas que tiene el nivel.
        /// </summary>
        private int m_cantidadDeBatallas;

        /// <summary>
        /// Lee el objetivo nroObjetivo del archivo xml y lo devuelve.
        /// </summary>
        /// <param name="nroObjetivo">El número de objetivo a leer.</param>
        /// <returns></returns>
        public void Cargar(int nroNivel)
        {
            string path = Utilidades.ObtenerPath(Programa.PATH_NIVEL + " \\nivel_" + nroNivel + ".xml");
            m_nroBatallaActual = 0;
            m_nroObjetivoActual = 0;

            if (path == null)
            {
                Log.Instancia.Debug("No se pueden cargar los objetivos. No se encuentra el archivo.");
            }

            XmlTextReader lector = new XmlTextReader(path);

            List<Objetivo> objetivos;
            Objetivo obj;

            Orden ord;
            List<Orden> ordenes = new List<Orden>();
            string pathImagen;
            try
            {
                while (lector.Read())
                {
                    if (lector.NodeType == XmlNodeType.Element && lector.Name == "batalla")
                    {
                        m_batallas[m_cantidadDeBatallas] = new Batalla();
                        objetivos = new List<Objetivo>();

                        while (lector.Read() && !(lector.NodeType == XmlNodeType.EndElement && lector.Name == "batalla"))
                        {
                            if (lector.NodeType == XmlNodeType.Element && lector.Name == "objetivo")
                            {
                                lector.MoveToAttribute("imagen");
                                pathImagen = null;

                                if (lector.Name == "imagen")
                                {
                                    pathImagen = Utilidades.ObtenerPath(lector.Value);
                                }

                                obj = new Objetivo(pathImagen);
                                obj.Ordenes = new Stack<Orden>();

                                while (lector.Read() && !(lector.NodeType == XmlNodeType.EndElement && lector.Name == "objetivo"))
                                {
                                    if (lector.NodeType == XmlNodeType.Element)
                                    {
                                        Point punto = new Point();
                                        Orden.TIPO id = Orden.TIPO.INVALIDA;

                                        if (lector.Name == "tomar")
                                        {
                                            id = Orden.TIPO.TOMAR_OBJETO;
                                        }

                                        if (lector.Name == "llegar")
                                        {
                                            id = Orden.TIPO.MOVER;
                                        }

                                        if (lector.Name == "trigger")
                                        {
                                            id = Orden.TIPO.TRIGGER;
                                        }

                                        if (lector.Name == "matar")
                                        {
                                            id = Orden.TIPO.MATAR;
                                        }

                                        //multiplico las posiciones por dos apra quee sten medidas en tiles chicos.
                                        lector.MoveToAttribute("i");
                                        punto.X = Convert.ToInt16(lector.Value) << 1;

                                        lector.MoveToAttribute("j");
                                        punto.Y = Convert.ToInt16(lector.Value) << 1;

                                        AnimObjeto animacionFuego = null;

                                        if (id == Orden.TIPO.TOMAR_OBJETO)
                                        {
                                            lector.MoveToAttribute("imagen");

                                            if (lector.Name == "imagen")
                                            {
                                                ord = new Orden(id, punto.X, punto.Y, lector.Value);
                                                ordenes.Add(ord);
                                            }
                                        }

                                        else if (id == Orden.TIPO.TRIGGER)
                                        {
                                            lector.MoveToAttribute("tipo");

                                            if (lector.Name == "tipo")
                                            {
                                                if (lector.Value == "fuego1")
                                                {
                                                    animacionFuego = new AnimObjeto(AdministradorDeRecursos.Instancia.Animaciones[Res.ANIM_FUEGO_1], punto.X, punto.Y);
                                                }
                                                if (lector.Value == "fuego2")
                                                {
                                                    animacionFuego = new AnimObjeto(AdministradorDeRecursos.Instancia.Animaciones[Res.ANIM_FUEGO_2], punto.X, punto.Y);
                                                }
                                                ord = new Orden(id, punto.X, punto.Y, animacionFuego);
                                                ordenes.Add(ord);
                                            }
                                            
                                        }
                                        else if (id == Orden.TIPO.MATAR)
                                        { 
                                           lector.MoveToAttribute("ancho");

                                           if (lector.Name == "ancho")
                                           {
                                               int ancho = Convert.ToInt16(lector.Value) << 1;

                                               ord = new Orden(id, punto.X, punto.Y, ancho);
                                               ordenes.Add(ord);
                                           }
                                        }
                                        else
                                        {
                                            ord = new Orden(id, punto.X, punto.Y);
                                            ordenes.Add(ord);
                                        }

                                        
                                    }
                                }
                                //termine de leer el objetivo.

                                //revierto las ordenes y las pongo en una pila.
                                for (int i = ordenes.Count - 1; i >= 0; i--)
                                {
                                    obj.Ordenes.Push(ordenes[i]);
                                }

                                objetivos.Add(obj);
                                //obj = new Objetivo();

                                ordenes = new List<Orden>();

                            }
                        }

                        //Termine de leer los objetivos de la batalla.
                        for (int i = objetivos.Count - 1; i >= 0; i--)
                        {
                            m_batallas[m_cantidadDeBatallas].m_objetivos.Push(objetivos[i]);
                        }

                        //La cantidad de objetivos  que tiene la batalla.
                        m_batallas[m_cantidadDeBatallas].CantidadDeObjetivos = objetivos.Count;

                        //Borro lo anterior
                        objetivos = new List<Objetivo>();

                        m_cantidadDeBatallas++;
                    }
                }
            }
            catch (Exception e)
            {
                lector.Close();
                Log.Instancia.Error("Error al leer el archivo  " + path + ", exc:" + e.Message);
            }
            lector.Close();
        }

        /// <summary>
        /// Devuelve el próximo objetivo que se tiene que cumplir.
        /// </summary>
        /// <returns></returns>
        public Objetivo ProximoObjetivo()
        {
            m_nroObjetivoActual++;

            m_cantidadeDeObjetivosCumplidos++;

            if (m_batallas[m_nroBatallaActual].m_objetivos.Count == 0)
            {
                m_nroBatallaActual++;
                m_nroObjetivoActual = 0;

                Log.Instancia.Debug("Paso a la siguiente batalla.......");

                if (m_nroBatallaActual >= m_cantidadDeBatallas)
                {
                    Log.Instancia.Debug("No hay mas objetivos... los cumpli a todos... gane!!");
                    return null;
                }
            }

            return m_batallas[m_nroBatallaActual].m_objetivos.Pop();
        }

        /// <summary>
        /// Devuelve el numero de objetivo actual.
        /// </summary>
        public int NroObjetivoActual
        {
            get
            {
                return m_nroObjetivoActual;
            }
        }

        /// <summary>
        /// El número de la batalla actual.
        /// </summary>
        public int NroBatallaActual
        {
            get
            {
                return m_nroBatallaActual;
            }
        }

        /// <summary>
        /// Devuelve la cantidad de objetivos actuales.
        /// </summary>
        public int CantidadDeObjetivosActuales
        {
            get
            {
                return m_batallas[m_nroBatallaActual].CantidadDeObjetivos;
            }
        }

        /// <summary>
        /// Devuelve la cantidad de objetivos totales, anteriores a esta batalla, 
        /// o sea la sumatoria de todas las cantidades de objetivos anteriores
        /// al objtivo actual.
        /// </summary>
        public int CantidadDeObjetivosCumplidos
        {
            get
            {
                return m_cantidadeDeObjetivosCumplidos;
            }
        }

        /// <summary>
        /// Devuelve la cantidad de batallas.
        /// </summary>
        public int CantidadDeBatallas
        {
            get
            {
                return m_cantidadDeBatallas;
            }
        }
    }
}
