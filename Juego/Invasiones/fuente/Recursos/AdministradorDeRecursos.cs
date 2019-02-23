using System;
using System.Collections.Generic;
using System.Text;
using System.IO;
using Invasiones.Debug;
using System.Collections;
using Invasiones.Dibujo;
using Invasiones.Sprites;
using System.Xml;
using Invasiones.Nivel.Unidades;
using System.Drawing;

namespace Invasiones.Recursos
{
    /// <summary>
    /// Contiene algunas herramientas que usaremos en todo el juego. Corresponde al patrón Singleton.
    /// </summary>
    public class AdministradorDeRecursos
    {
        #region Declaraciones

        /// <summary>
        /// Todas las superficies en el juego.
        /// </summary>
        private Hashtable m_imagenes;

        /// <summary>
        /// Todas las rutas completas de las fuentes.
        /// </summary>
        private string[] m_pathsFuentes;

        /// <summary>
        /// Las rutas completas de todos los tilesets y los mapas.
        /// </summary>
        private string[] m_pathsEscenarios;

        /// <summary>
        /// Los paths para todos los sonidos.
        /// </summary>
        private string[] m_pathsSonidos;

        /// <summary>
        /// Toda la información de los sprites
        /// </summary>
        private Sprite[] m_sprites;

        /// <summary>
        /// Todas las rutas completas a las imágenes.
        /// </summary>
        private string[] m_pathsImagenes;

        /// <summary>
        /// Contiene los path de las unidades.
        /// </summary>
        private string[] m_pathsUnidades;

        /// <summary>
        /// Todas las fuentes que se van a utilizar.
        /// </summary>
        private Fuente[] m_fuentes;

        /// <summary>
        /// La instancia de la clase.
        /// </summary>
        private static AdministradorDeRecursos s_instancia;

        /// <summary>
        /// Los diferentes tipos de unidades que hay en el nivel.
        /// </summary>
        private Unidad[] m_tipoDeUnidades;
        #endregion

        #region Properties
        /// <summary>
        /// Todas las animaciones del juego
        /// </summary>
        private Animaciones[] m_animaciones;

        /// <summary>
        /// Crea una lista de sprites j la carga segun la información encontrada en el archivo xml
        /// </summary>
        /// <returns>true si pudo cargar correctamente</returns>
        public bool LeerInfoAnimaciones()
        {
            bool ok = true;
            short id = 0;

            string path = Utilidades.ObtenerPath(Programa.ARCHIVO_XML_RECURSOS);

            if (path == null)
            {
                Log.Instancia.Error("No existe el archivo " + Programa.ARCHIVO_XML_RECURSOS + ".");
                return false;
            }


            short ticks = 0;
            short frameAncho = 0;
            short frameAlto = 0;
            string imgpath = "";


            try
            {
                XmlTextReader reader = new XmlTextReader(path);
                reader.MoveToContent();
                reader.ReadStartElement();

                m_animaciones = new Animaciones[Res.ANIM_COUNT];
                Point offsets = new Point();

                while (reader.Read())
                {
                    if (reader.NodeType == XmlNodeType.Element && reader.Name == "anims")
                    {
                        while (reader.Read() && !(reader.NodeType == XmlNodeType.EndElement && reader.Name == "anims"))
                        {
                            if (reader.NodeType == XmlNodeType.Element && reader.Name == "animacion")
                            {

                                while (reader.MoveToNextAttribute())
                                {
                                    if (reader.Name == "imagepath")
                                    {
                                        imgpath = Utilidades.ObtenerPath(reader.Value);
                                        if (imgpath == null)
                                        {
                                            ok = false;
                                        }
                                    }

                                    if (reader.Name == "framewidth")
                                    {
                                        frameAncho = Convert.ToInt16(reader.Value);
                                        if (frameAncho < 0)
                                        {
                                            frameAncho = 0;
                                            ok = false;
                                        }
                                    }

                                    if (reader.Name == "frameheight")
                                    {
                                        frameAlto = Convert.ToInt16(reader.Value);
                                        if (frameAlto < 0)
                                        {
                                            frameAlto = 0;
                                            ok = false;
                                        }
                                    }

                                    if (reader.Name == "frameticks")
                                    {
                                        ticks = Convert.ToInt16(reader.Value);
                                        if (ticks < 0)
                                        {
                                            ticks = 0;
                                            ok = false;
                                        }
                                    }

                                    if (reader.Name == "offsetX")
                                    {
                                        offsets.X = Convert.ToInt16(reader.Value);
                                    }

                                    if (reader.Name == "offsetY")
                                    {
                                        offsets.Y = Convert.ToInt16(reader.Value);
                                    }
                                }

                                m_animaciones[id] = new Animaciones(0, imgpath, ticks, frameAncho,frameAlto, offsets);
                                frameAncho = frameAlto = 0;
                                id++;

                            }
                        }
                    }
                }
                reader.Close();
            }
            catch (Exception e)
            {
                Log.Instancia.Error("No se pudo cargar correctamente" + e.Message);
                return false;
            }
            return ok;
        }

        /// <summary>
        /// Todas las animaciones.
        /// </summary>
        public Animaciones[] Animaciones
        {
            get
            {
                return m_animaciones;
            }
        }

        /// <summary>
        /// Las rutas completas de todos los sonidos.
        /// </summary>
        public string[] PathsSonidos
        {
            get
            {
                return m_pathsSonidos;
            }
        }

        /// <summary>
        /// Las rutas completas de todos los tilesets y los mapas.
        /// </summary>
        public string[] PathsEscenarios
        {
            get
            {
                return m_pathsEscenarios;
            }
        }

        /// <summary>
        /// Las rutas completas de todas las fuentes.
        /// </summary>
        public string[] PathsFuentes
        {
            get
            {
                return m_pathsFuentes;
            }
        }

        /// <summary>
        /// Las rutas completas de todas las imágenes.
        /// </summary>
        public string[] PathsImagenes
        {
            get
            {
                return m_pathsImagenes;
            }
        }

        /// <summary>
        /// Las rutas completas de todas las unidades.
        /// </summary>
        public string[] PathsUnidades
        {
            get
            {
                return m_pathsUnidades;
            }
        }

        /// <summary>
        /// Todos los sprites.
        /// </summary>
        public Sprite[] Sprites
        {
            get
            {
                return m_sprites;
            }
        }

        /// <summary>
        /// Devuelve los distintos tipos de unidades.
        /// </summary>
        public Unidad[] TipoDeUnidades
        {
            get
            {
                return m_tipoDeUnidades;
            }
        }

        /// <summary>
        /// Devuelve las fuentes cargadas.S
        /// </summary>
        public Fuente[] Fuentes
        {
            get
            {
                return m_fuentes;
            }
        }
        #endregion

        #region Constructores
        /// <summary>
        /// constructor.
        /// </summary>
        private AdministradorDeRecursos()
        {
        }
        #endregion

        #region Destructor - libera recursos
        ~AdministradorDeRecursos()
        {
            this.Dispose();
        }

        /// <summary>
        /// Libero todoss os recursos liberados en el programa
        /// </summary>
        public virtual void Dispose()
        {
            //Libero las fuentes
            if (m_fuentes != null)
            {
                foreach (Fuente fuente in m_fuentes)
                {
                    fuente.Dispose();
                }
            }

            //Libero las imagenes
            if (m_imagenes != null)
            {
                foreach (Superficie imagen in m_imagenes.Values)
                {
                    imagen.Dispose();
                }
            }
        }
        #endregion

        #region Metodos Static
        /// <summary>
        /// Devuelve la instancia de la clase.
        /// </summary>
        public static AdministradorDeRecursos Instancia
        {
            get
            {
                if (s_instancia == null)
                {
                    s_instancia = new AdministradorDeRecursos();
                }
                return s_instancia;
            }
        }
        #endregion

        #region Metodos Unsafe
        /// <summary>
        /// Devuelve el Surface asociado con el nombre del archivo dado.
        /// </summary>
        /// <param name="nombre">El nombre del archivo de la imagen.</param>
        unsafe public Superficie ObtenerImagen(string nombre)
        {

            if (m_imagenes == null)
            {
                m_imagenes = new Hashtable();
            }

            if (!m_imagenes.ContainsKey(nombre))
            {
                string path = Utilidades.ObtenerPath(nombre);

                if (path != null)
                {
                    Superficie img = new Superficie(path);
                    m_imagenes.Add(nombre, img);
                }
                else
                {
                    return null;
                }
            }
            return (Superficie)m_imagenes[nombre];
        }

        /// <summary>
        /// Devuelve el Surface asociado con el nombre dado.
        /// </summary>
        /// <param name="nombre">El nombre de la imagen.</param>
        unsafe public Superficie ObtenerImagen(int id)
        {

            if (m_imagenes == null)
            {
                m_imagenes = new Hashtable();
            }

            if (m_imagenes[id] == null)
            {
                string path = Utilidades.ObtenerPath(m_pathsImagenes[id]);
                if (path != null)
                {
                    Superficie img = new Superficie(path);
                    m_imagenes.Add(id, img);
                }
                else
                {
                    return null;
                }
            }
            return (Superficie)m_imagenes[id];
        }
        #endregion

        #region Metodos
        /// <summary>
        /// Carga los paths de los recursos
        /// </summary>
        /// <returns>true si pudo cargar todos los archivos en el xml de los recursos. 
        /// false si hubo algun error.</returns>
        public bool CargarPathsRecursos()
        {
            string path = Utilidades.ObtenerPath(Programa.ARCHIVO_XML_RECURSOS);
            bool ok = true;
            if (path == null)
            {
                Log.Instancia.Error("No existe el archivo " + Programa.ARCHIVO_XML_RECURSOS + ".");
                return false;
            }


            try
            {
                XmlTextReader reader = new XmlTextReader(path);
                reader.MoveToContent();
                reader.ReadStartElement();

                while (reader.Read())
                {

                    if (reader.NodeType == XmlNodeType.Element)
                    {
                        //leo las fuentes
                        if (reader.Name == "fuentes")
                        {
                            if (!LeerPathsFuentes(ref reader))
                            {
                                ok = false;
                            }
                        }

                        //leo las imagenes
                        if (reader.Name == "imagenes")
                        {
                            if (!LeerPathsImagenes(ref reader))
                            {
                                ok = false;
                            }
                        }

                        if (reader.Name == "unidades")
                        {
                            if (!LeerPathsUnidades(ref reader))
                            {
                                ok = false;
                            }
                        }

                        //leo los escenarios
                        if (reader.Name == "escenarios")
                        {
                            if (!LeerPathsEscenarios(ref reader))
                            {
                                ok = false;
                            }
                        }

                        //leo los sonidos
                        if (reader.Name == "sonidos")
                        {
                            if (!LeerPathsSonidos(ref reader))
                            {
                                ok = false;
                            }
                        }
                    }
                }

                if (!ok)
                {
                    Log.Instancia.Error("==================Uno o mas archivos no pudieron ser cargados================");
                }
                reader.Close();
            }
            catch (Exception e)
            {
                Log.Instancia.Error("Error al leer el archivo " + Programa.ARCHIVO_XML_RECURSOS + "." + e.Message);
                return false;
            }

            return true;
        }

        /// <summary>
        /// Lee los paths de las unidades.
        /// </summary>
        /// <param name="reader">La referencia al lector xml.</param>
        /// <returns>true si pudo leer correctamente.</returns>
        private bool LeerPathsUnidades(ref XmlTextReader reader)
        {
            bool ok = true;
            int i = 0;
            m_pathsUnidades = new string[Res.UNIDAD_COUNT];
            try
            {
                while (reader.Read() && !(reader.NodeType == XmlNodeType.EndElement && reader.Name == "unidades"))
                {

                    if (reader.NodeType == XmlNodeType.Element)
                    {

                        if (reader.Name == "unidad")
                        {

                            reader.MoveToAttribute("file");
                            if (reader.Name == "file")
                            {
                                string filename = reader.Value;
                                m_pathsUnidades[i] = Utilidades.ObtenerPath(filename);
                                if (m_pathsUnidades[i++] == null)
                                {
                                    ok = false;
                                }
                            }
                        }
                    }
                }
            }
            catch (Exception e)
            {
                Log.Instancia.Error("Error al leer el archivo " + Programa.ARCHIVO_XML_RECURSOS + "." + e.Message);
                return false;
            }
            return ok;
        }

        /// <summary>
        /// Lee los paths de las imágenes
        /// </summary>
        /// <param name="reader">el lector xml de los recursos</param>
        /// <returns> true si no encontro ningun error</returns>
        private bool LeerPathsSonidos(ref XmlTextReader reader)
        {
            bool ok = true;
            int i = 0;
            m_pathsSonidos = new string[Res.SND_COUNT + Res.SFX_COUNT];
            try
            {
                while (reader.Read() && !(reader.NodeType == XmlNodeType.EndElement && reader.Name == "sonidos"))
                {

                    if (reader.NodeType == XmlNodeType.Element)
                    {
                        if (reader.Name != "musica" && reader.Name != "sfx")
                        {
                            string filename = reader.ReadString();
                            m_pathsSonidos[i] = Utilidades.ObtenerPath(filename);
                            if (m_pathsSonidos[i++] == null)
                            {
                                ok = false;
                            }
                        }
                    }
                }
            }
            catch (Exception e)
            {
                Log.Instancia.Error("Error al leer el archivo " + Programa.ARCHIVO_XML_RECURSOS + "." + e.Message);
                return false;
            }
            return ok;
        }

        /// <summary>
        /// Lee los paths de las imágenes
        /// </summary>
        /// <param name="reader">el lector xml de los recursos</param>
        /// <returns> true si no encontro ningun error</returns>
        private bool LeerPathsEscenarios(ref XmlTextReader reader)
        {
            m_pathsEscenarios = new string[Res.TLS_COUNT + Res.MAP_COUNT];

            int i = 0;
            bool ok = true;
            try
            {
                while (reader.Read() && !(reader.NodeType == XmlNodeType.EndElement && reader.Name == "escenarios"))
                {
                    if (reader.NodeType == XmlNodeType.Element)
                    {
                        if (reader.Name != "tilesets" && reader.Name != "mapas")
                        {

                            m_pathsEscenarios[i] = Utilidades.ObtenerPath(reader.ReadString());
                            if (m_pathsEscenarios[i++] == null)
                            {
                                ok = false;
                            }
                        }
                    }
                }
            }
            catch (Exception e)
            {
                Log.Instancia.Error("Error al leer el archivo " + Programa.ARCHIVO_XML_RECURSOS + "." + e.Message);
                return false;
            }
            return ok;
        }

        /// <summary>
        /// Deuelve una copia de la imagen dada por parámetro.
        /// </summary>
        /// <param name="pathImagen">El archivo a copiar.</param>
        /// <returns>una Superficie con la copia.</returns>
        public Superficie ObtenerCopiaImagen(string pathImagen)
        {
            Superficie sup = ObtenerImagen(pathImagen);

            return new Superficie(sup);
        }

        /// <summary>
        /// Lee la informacion de los sprites desde el archivo res.xml
        /// </summary>
        /// <returns>true si pudo leer correctamente.</returns>
        public bool LeerInfoSprites()
        {
            string path = Utilidades.ObtenerPath(Programa.ARCHIVO_XML_RECURSOS);
            bool ok = true;
            if (path == null)
            {
                Log.Instancia.Error("No existe el archivo " + Programa.ARCHIVO_XML_RECURSOS + ".");
                return false;
            }
            string nombreDelSprite = "";
            short velocidad = 0;
            string nombreDelArchivo = "";
            List<Animaciones> animacionesLeidas = new List<Animaciones>();
            short anchoDelFrame = 0;
            short altoDelFrame = 0;
            short ticksDeCadaFrame = 0;
            int i = 0;
            Point offsets;


            try
            {
                XmlTextReader reader = new XmlTextReader(path);
                reader.MoveToContent();
                reader.ReadStartElement();

                while (reader.Read())
                {
                    nombreDelSprite = "";
                    velocidad = 0;
                    nombreDelArchivo = "";
                    anchoDelFrame = 0;
                    altoDelFrame = 0;
                    ticksDeCadaFrame = 0;
                    offsets = new Point();


                    if (reader.NodeType == XmlNodeType.Element)
                    {

                        if (reader.Name == "sprites")
                        {
                            i = 0;
                            m_sprites = new Sprite[Res.SPR_COUNT];

                            while (reader.Read() && !(reader.NodeType == XmlNodeType.EndElement && reader.Name == "sprites"))
                            {
                                if (reader.NodeType == XmlNodeType.Element)
                                {
                                    if (reader.Name == "sprite")
                                    {
                                        animacionesLeidas.Clear();

                                        while (reader.MoveToNextAttribute())
                                        {
                                            if (reader.Name == "name") { nombreDelSprite = reader.Value; }
                                            if (reader.Name == "velocity") { velocidad = Convert.ToInt16(reader.Value); }
                                        }

                                        while (reader.Read() && reader.Name != "sprite")
                                        {

                                            if (reader.Name == "animpak")
                                            {

                                                while (reader.Read() && !(reader.NodeType == XmlNodeType.EndElement && reader.Name == "animpak"))
                                                {
                                                    if (reader.NodeType == XmlNodeType.Element)
                                                    {
                                                        if (reader.Name == "image")
                                                        {
                                                            while (reader.MoveToNextAttribute())
                                                            {
                                                                if (reader.Name == "path")
                                                                {
                                                                    nombreDelArchivo = Utilidades.ObtenerPath(reader.Value);
                                                                    if (nombreDelArchivo == null)
                                                                    {
                                                                        ok = false;
                                                                    }
                                                                }

                                                                if (reader.Name == "framewidth") { anchoDelFrame = Convert.ToInt16(reader.Value); }

                                                                if (reader.Name == "frameheight") { altoDelFrame = Convert.ToInt16(reader.Value); }

                                                                if (reader.Name == "frameticks") { ticksDeCadaFrame = Convert.ToInt16(reader.Value); }
                                                                if (reader.Name == "offsetX")
                                                                {
                                                                    offsets.X = Convert.ToInt16(reader.Value);
                                                                }
                                                                if (reader.Name == "offsetY")
                                                                {
                                                                    offsets.Y = Convert.ToInt16(reader.Value);
                                                                }
                                                            }
                                                        }

                                                    }
                                                }

                                                animacionesLeidas.Add(new Animaciones(0, nombreDelArchivo, ticksDeCadaFrame, anchoDelFrame, altoDelFrame, offsets));

                                            }


                                        }

                                        m_sprites[i] = new Sprite();
                                        m_sprites[i].Animaciones = new Animaciones[animacionesLeidas.Count];

                                        int indice = 0;

                                        foreach (Animaciones anim in animacionesLeidas)
                                        {
                                            m_sprites[i].AgregarAnimacion(indice++, anim);
                                        }
                                        i++;
                                    }

                                }
                            }
                        }
                    }
                }

                reader.Close();
            }
            catch (Exception e)
            {
                Log.Instancia.Error("No se pudo cargar correctamente" + e.Message);
                return false;
            }

            return ok;
        }

        /// <summary>
        /// Lee los paths de las imágenes
        /// </summary>
        /// <param name="reader">el lector xml de los recursos</param>
        /// <returns> true si no encontro ningun error</returns>
        public bool LeerPathsImagenes(ref XmlTextReader reader)
        {
            int i = 0;
            bool ok = true;

            m_pathsImagenes = new string[Res.IMG_COUNT];
            try
            {
                while (reader.Read() && !(reader.NodeType == XmlNodeType.EndElement && reader.Name == "imagenes"))
                {
                    if (reader.NodeType == XmlNodeType.Element)
                    {
                        m_pathsImagenes[i] = Utilidades.ObtenerPath(reader.ReadString());
                        if (m_pathsImagenes[i++] == null)
                        {
                            ok = false;
                        }
                    }
                }
            }
            catch (Exception e)
            {
                Log.Instancia.Error("Error al leer el archivo " + Programa.ARCHIVO_XML_RECURSOS + "." + e.Message);
                return false;
            }
            return ok;
        }

        /// <summary>
        /// Lee lospaths de las fuentes
        /// </summary>
        /// <param name="reader">el lector xml de los recursos</param>
        /// <returns> true si no encontro ningun error</returns>
        private bool LeerPathsFuentes(ref XmlTextReader reader)
        {
            bool ok = true;
            try
            {
                int i = 0;
                string path = "";
                m_pathsFuentes = new string[Res.FNT_COUNT];

                while (reader.Read() && !(reader.NodeType == XmlNodeType.EndElement && reader.Name == "fuentes"))
                {
                    if (reader.NodeType == XmlNodeType.Element)
                    {
                        path = reader.ReadString();
                        m_pathsFuentes[i] = Utilidades.ObtenerPath(path);
                        if (m_pathsFuentes[i] == null)
                        {
                            ok = false;
                        }
                        i++;
                    }
                }
            }
            catch (Exception e)
            {
                Log.Instancia.Error("Excepcion al leer el xml de los recursos. " + e.Message);
                return false;
            }
            return ok;
        }

        /// <summary>
        /// Carga los tipos de unidades.
        /// </summary>
        public void CargarTipoDeUnidades()
        {
            m_tipoDeUnidades = new Unidad[Res.UNIDAD_COUNT];

            for (int i = 0; i < Res.UNIDAD_COUNT; i++)
            {
                m_tipoDeUnidades[i] = new Unidad();
                m_tipoDeUnidades[i].LeerUnidad(i);
            }
        }

        /// <summary>
        /// Carga las fuentes que utilizara.
        /// </summary>
        /// <returns></returns>
        public bool CargarFuentes()
        {
            if (m_fuentes != null)
                return false;

            m_fuentes = new Fuente[(int)Definiciones.FNT.TOTAL];
            m_fuentes[(int)Definiciones.FNT.SANS12] = new Fuente(Res.FNT_SANS, 12);
            m_fuentes[(int)Definiciones.FNT.SANS14] = new Fuente(Res.FNT_SANS, 14);
            m_fuentes[(int)Definiciones.FNT.SANS18] = new Fuente(Res.FNT_SANS, 18);
            m_fuentes[(int)Definiciones.FNT.SANS20] = new Fuente(Res.FNT_SANS, 20);
            m_fuentes[(int)Definiciones.FNT.SANS24] = new Fuente(Res.FNT_SANS, 24);
            m_fuentes[(int)Definiciones.FNT.SANS28] = new Fuente(Res.FNT_SANS, 28);

            m_fuentes[(int)Definiciones.FNT.LBLACK12] = new Fuente(Res.FNT_LBLACK, 12);
            m_fuentes[(int)Definiciones.FNT.LBLACK14] = new Fuente(Res.FNT_LBLACK, 14);
            m_fuentes[(int)Definiciones.FNT.LBLACK18] = new Fuente(Res.FNT_LBLACK, 18);
            m_fuentes[(int)Definiciones.FNT.LBLACK20] = new Fuente(Res.FNT_LBLACK, 20);
           
            m_fuentes[(int)Definiciones.FNT.LBLACK28] = new Fuente(Res.FNT_LBLACK, 28);

            return m_fuentes[(int)Definiciones.FNT.SANS12] != null;
        }

        /// <summary>
        /// Carga una imagen con formato png-24
        /// </summary>
        /// <param name="id">EL identificador de la imagen</param>
        /// <returns>la imagen cargada.</returns>
        public Superficie ObtenerImagenAlpha(int id)
        {

            if (m_imagenes == null)
            {
                m_imagenes = new Hashtable();
            }

            if (m_imagenes[id] == null)
            {
                string path = Utilidades.ObtenerPath(m_pathsImagenes[id]);
                if (path != null)
                {
                    Superficie img = new Superficie(path, true);
                    m_imagenes.Add(id, img);
                }
                else
                {
                    return null;
                }
            }
            return (Superficie)m_imagenes[id];
        }
        #endregion
    }
}