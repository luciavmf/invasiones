using System;
using System.Collections.Generic;
using System.Text;
using System.IO;
using Invasiones.Recursos;

namespace Invasiones.Debug
{
    /// <summary>
	/// Clase utilizada para loguear información de debug, error, advertencias. Loguea
	/// por pantalla y guarda estos mensajes en un archivo de texto. Se puede habilitar
	/// y deshabilitar el log. Si la versión actual en la que está compilado el
	/// programa es "release", se deshabilita el log.
	/// </summary>
    public class Log
    {
        #region Declaraciones
#if DEBUG
        /// <summary>
        /// El nombre del archivo de salida
        /// </summary>
        private string m_nombreDeArchivo = "output.log";

        /// <summary>
        /// El archivo utilizado para loguear
        /// </summary>
        private static StreamWriter s_arcvhivoEscritor;
#endif
        /// <summary>
		/// Habilita o deshabilita el log.
		/// </summary>
        private static bool s_habilitado = true;
        
		/// <summary>
		/// La instancia de la clase.
		/// </summary>
        private static  Log s_instancia;
        #endregion

        #region Properties
        /// <summary>
        /// Devuelve la instancia del Log.
        /// </summary>
        public static Log Instancia
        {
            get
            {
                if (s_instancia == null)
                {
                    s_instancia = new Log();
                }

                return s_instancia;
            }
        }
        #endregion

        #region Constructores
        /// <summary>
		/// Contructor de la clase. Se declara privado para que solo haya una instancia.
		/// </summary>
        private Log() 
        {  
#if (DEBUG)
            string filename = Utilidades.CrearPath(m_nombreDeArchivo);
            if (s_arcvhivoEscritor == null)
            {
                s_arcvhivoEscritor = new StreamWriter(new FileStream(filename, FileMode.Create, FileAccess.Write));
                s_arcvhivoEscritor.AutoFlush = true;
            }
#endif
        }
        #endregion

        #region Destructor - libera recursos
        /// <summary>
        /// Desructor de la clase. Cierra el archivo de log.
        /// </summary>
        ~Log()
        {
			this.Dispose();
        }

		public virtual void Dispose()
		{
#if (DEBUG)
			Console.WriteLine("bye bye log ");
			s_arcvhivoEscritor.Close();
			s_arcvhivoEscritor = null;
#endif
			GC.SuppressFinalize(this);
        }
        #endregion

        #region Metodos
        /// <summary>
		/// Habilita o deshabilita el log.
		/// </summary>
		/// <param name="enable">True para habilitar, False para deshabilitar.</param>
        private void Habilitar(bool enable)
        {
#if (DEBUG)
            s_habilitado = enable;
#else
            s_habilitado = false;
#endif
        }

        /// <summary>
		/// Es el método principal de logueo, utilizada por las demas funciones de logueo.
		/// </summary>
		/// <param name="level">El nivel del log. Debug, Informar, Error  or Warn.</param>
		/// <param name="strMessage">El mensaje a loguear</param>
        private void Loguear(string level, string strMessage)
        {

            if (s_habilitado == false) return;
#if (DEBUG)
            string strLog;
            string strTimeStamp;

            // Le pone la hora j fecha actual
            strTimeStamp = DateTime.Now.ToString();

            // Concatena la info en un string
            strLog = "[" + strTimeStamp + "] " + level + " - " + strMessage;

            // Lo imprime por pantalla
            Console.WriteLine(strLog);

				if (s_arcvhivoEscritor != null)
				{
					s_arcvhivoEscritor.WriteLine(strLog);
				}
	
#endif
        }

        /// <summary>
		/// Loguea un mensaje con la leyenda Debug.
		/// </summary>
		/// <param name="strMessage">El mensaje a loguear.</param>
        public void Debug(string strMessage)
        {
            Loguear("DEBUG", strMessage);
        }

		/// <summary>
		/// Loguea un mensaje con la leyenda Informar.
		/// </summary>
		/// <param name="strMessage">El mensaje a loguear.</param>
        public void Informar(string strMessage)
        {
            Loguear("INFO", strMessage);
        }

		/// <summary>
		/// Loguea un mensaje con la leyenda Warn
		/// </summary>
		/// <param name="strMessage">El mensaje a loguear.</param>
        public void Advertir(string strMessage)
        {
            Loguear("WARN", strMessage);
        }

		/// <summary>
		/// Loguea un mensaje con la leyenda Error.
		/// </summary>
		/// <param name="strMessage">the message to log.</param>
        public void Error(string strMessage)
        {
            Loguear("ERROR", strMessage);
        }

		/// <summary>
		/// Loguea un mensaje con la leyenda Error.
		/// </summary>
		/// <param name="exception">La excepcion a loguear.</param>
        public void Error(Exception exception)
        {
            Error(exception.Message);
        }
        #endregion
    }
}