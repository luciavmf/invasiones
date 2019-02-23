using System;
using System.Collections.Generic;
using System.Text;
using Invasiones.Recursos;
using System.Xml;
using Invasiones.Debug;
using System.Drawing;
using Invasiones.Nivel.Unidades;
using Invasiones.Dibujo;
using Invasiones.GUI;

namespace Invasiones.Nivel
{
    /// <summary>
    /// Representa a un objetivo que se debe cumplir para pasar del nivel.
    /// </summary>
    public class Objetivo
    {
        /// <summary>
        /// Las ordenes que hay que hacer para cumplir con el objetivo.
        /// </summary>
        private Stack<Orden> m_ordenes;

        private string m_pathImagen;

        /// <summary>
        /// Constructor.
        /// </summary>
        public Objetivo(string pathImagen)
        {
            m_pathImagen = pathImagen;
        }

        /// <summary>
        /// Las órdenes que componen el objetivo.
        /// </summary>
        public Stack<Orden> Ordenes
        {
            get
            {
                return m_ordenes;
            }
            set
            {
                m_ordenes = value;
            }
        }

        /// <summary>
        /// Dice cual es l orden actual;
        /// </summary>
        /// <returns></returns>
        public Orden ProximaOrden()
        {
            if (m_ordenes.Count > 0)
            {
                Orden orn = m_ordenes.Pop();
                return orn;
            }

            return null;
        }
    }
}
