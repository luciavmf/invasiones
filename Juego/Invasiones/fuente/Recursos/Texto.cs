using System;
using System.Collections.Generic;
using System.Text;
using System.Xml;
using System.IO;
using Invasiones.Debug;

namespace Invasiones.Recursos
{
    /// <summary>
    /// Clase utilizada para cargar todos los textos, desde el archivo xml.
    /// Cachea todos los strings.
    /// </summary>
    public class Texto
    {
        #region Metodos Static
        /// <summary>
        /// Contiene todos los strings.
        /// </summary>
        private static string [] s_strings;

        /// <summary>
        ///Carga el texto básico para correr la aplicación.
        /// </summary>
        public static bool Cargar()
        {
            s_strings = new string[Res.STR_COUNT];
            string path = Utilidades.ObtenerPath(Programa.ARCHIVO_XML_TEXTOS);

            if (path == null)
            {
                Log.Instancia.Error("No se encuentra el archivo " + Programa.ARCHIVO_XML_TEXTOS + ".");
                return false;
            }

            try
            {
                XmlTextReader lector = new XmlTextReader(path);

                lector.MoveToContent();
                lector.ReadStartElement();
                int i = 0;
                while (lector.Read())
                {
                    if (lector.NodeType == XmlNodeType.Element)
                    {
                        s_strings[i++] = lector.ReadString();
                    }
                }
                lector.Close();
            }
            catch (Exception e)
            {
                Log.Instancia.Error("Error al leer el archivo" + Programa.ARCHIVO_XML_TEXTOS + "." +
                      e.Message);
                return false;
            }
            return true;
        }

        ///<summary>
        ///Devuelve los strings utilizados.
        ///</summary>
        public static string[] Strings
        {
            get
            {
                if (s_strings == null)
                    
                {
                    Cargar();
                }
                return s_strings;
            }
        }
        #endregion
    }
}