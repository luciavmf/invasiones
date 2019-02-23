using System;
using System.IO;
using Invasiones.Debug;

namespace Invasiones.Recursos
{
	/// <summary>
	/// Contiene algunas herramientas que usaremos en todo el juego. Corresponde al patrón Singleton.
	/// </summary>
	public class Utilidades
    {
        #region Metodos Static
        /// <summary>
		/// Devuelve el path completo del string pasado por parámetro.
		/// </summary>
		/// <param name="str">El nombre del archivo.</param>
		public static string ObtenerPath(string str)
		{
			string path1, path2;
			if (str == null || str == "")
			{
				Log.Instancia.Advertir("ObtenerPath: nombre de archivo no válido");
				return null;
			}

			path1 = Path.GetFullPath(Path.Combine(Programa.PATH_DATA_DEL_PROG, str));
			path2 = Path.GetFullPath(Path.Combine(Programa.PATH_DATA, str));

			if (File.Exists(path1))
			{
				return path1;
			}
			if (File.Exists(path2))
			{
				return path2;
			}

			Log.Instancia.Advertir("ObtenerPath: no existe el archivo \"" + str + "\"");
			return null;
		}

		/// <summary>
		/// Crea un padre path. Utilizado para cuando quiero crear archivos nuevos.
		/// </summary>
		/// <param name="str">El nombre del archivo.</param>
		public static string CrearPath(string str)
		{
			string path;
			path = Path.GetFullPath(Path.Combine(Directory.GetCurrentDirectory(), str));
			return path;
        }
        #endregion
    }
}