using System;
using System.Collections.Generic;
using System.Text;
using System.Xml;
using System.IO;

namespace XmlIdExporter
{
    class Program
    {

        public const string XML_PATH = "..\\..\\..\\..\\Juego\\Invasiones\\data";

        public const string RES_FILE = "res.xml";
        public const string STRING_FILE = "strings.xml";

        public const string OUTPUT_PATH = "..\\..\\..\\..\\Juego\\Invasiones\\fuente\\Recursos";
        public const string OUTPUT_FILE = "Res.cs";

        //public const string NIVEL_FILE = "nivel1.xml";


        static void Main(string[] args)
        {
            GenerarIdsArchivoRes();
        }

    
        private static void GenerarIdsArchivoRes()
        {
            StreamWriter output = null;
            try
            {
                output = new StreamWriter(new FileStream(Path.GetFullPath(Path.Combine(OUTPUT_PATH, OUTPUT_FILE)), FileMode.Create, FileAccess.Write));
            }
            catch (Exception e)
            {
                Console.WriteLine("No se puede crear el archivo de salida. " + e.Message);
                return;
            }



            output.WriteLine("//Clase autogenerada por XmlIdExporter.exe");
            output.WriteLine("namespace Invasiones");
            output.WriteLine("{");
            output.WriteLine("\tpublic class Res");
            output.WriteLine("\t{");


            //Leo el archivo de strings
            string path = Path.GetFullPath(Path.Combine(XML_PATH, STRING_FILE));
            if (!File.Exists(path))
            {
                Console.WriteLine("Error -  no existe el archivo " + path);
            }

            XmlTextReader reader = new XmlTextReader(path);
            int index = 0;
            output.WriteLine("\n\n\t\t//---------------\n\t\t//String Ids\n");
            while (reader.Read())
            {
                if (reader.NodeType == XmlNodeType.Element)
                {
                    if (reader.Name != "strings")
                    {
                        output.WriteLine("\t\tpublic const int STR_" + reader.Name.ToUpper() + " = " + (index++) + ";");
                    }
                }
            }

            output.WriteLine("\t\tpublic const int STR_COUNT = " + index + ";");

            reader.Close();
            reader = null;



            //leo el archivo res

            path = Path.GetFullPath(Path.Combine(XML_PATH, RES_FILE));
            if (!File.Exists(path))
            {
                Console.WriteLine("Error -  no existe el archivo " + path);
            }
            reader = new XmlTextReader(path);

            int subIndex = 0;
            string lastSpriteReaded = "";
            int lastWritten = 0;

            while (reader.Read())
            {
                if (reader.NodeType == XmlNodeType.Element)
                {

                    // Leo las unidades
                    if (reader.Name == "unidades")
                    {
                       
                        index = 0;
                        output.WriteLine("\n\n\t\t//---------------\n\t\t//Unidades Ids\n");
                        while (reader.Read() && !(reader.NodeType == XmlNodeType.EndElement && reader.Name == "unidades"))
                        {
                            if (reader.NodeType == XmlNodeType.Element && reader.Name == "unidad")
                            {
                                reader.MoveToAttribute("name");
                                if (reader.Name == "name")
                                {
                                    output.WriteLine("\t\tpublic const int UNIDAD_" + reader.Value.ToUpper() + " = " + (index++) + ";");
                                }
                            }

                        }
                        output.WriteLine("\t\tpublic const int UNIDAD_COUNT = " + index + ";");

                    }

                    // leo las fuentes
                    if (reader.Name == "fuentes")
                    {
                        index = 0;
                        output.WriteLine("\n\n\t\t//---------------\n\t\t//Fonts Ids\n");                       
                        while (reader.Read() && !(reader.NodeType == XmlNodeType.EndElement && reader.Name == "fuentes"))
                        {
                            if (reader.NodeType == XmlNodeType.Element)
                            {
                                output.WriteLine("\t\tpublic const int FNT_" + reader.Name.ToUpper() + " = " + (index++) + ";");
                            }

                        }
                        output.WriteLine("\t\tpublic const int FNT_COUNT = " + index + ";");
                    }


                    // leo las imagenes
                    if (reader.Name == "imagenes")
                    {
                        index = 0;
                        output.WriteLine("\n\n\t\t//---------------\n\t\t//Images Ids");
                        while (reader.Read() && !(reader.NodeType == XmlNodeType.EndElement && reader.Name == "imagenes"))
                        {
                            if (reader.NodeType == XmlNodeType.Element)
                            {
                                output.WriteLine("\t\tpublic const int IMG_" + reader.Name.ToUpper() + " = " + (index++) + ";");
                            }


                        }
                        output.WriteLine("\n\t\tpublic const int IMG_COUNT = " + (index) + ";");
                    }

                    //leo los sprites
                    if (reader.Name == "sprites")
                    {
                        index = 0;
                        subIndex = 0;
						int packCount=0;
                        output.WriteLine("\n\n\t\t//---------------\n\t\t//Sprite Ids");

                        while (reader.Read() && !(reader.NodeType == XmlNodeType.EndElement && reader.Name == "sprites"))
                        {
                            if (reader.NodeType == XmlNodeType.Element)
                            {

                                if (reader.Name == "sprite")
                                {

									if (lastSpriteReaded != "")
									{
										output.WriteLine("\t\tpublic const int SPR_" + lastSpriteReaded + "_PACK_COUNT = " + packCount + ";");
									}

									packCount = 0;
									subIndex = 0;

                                    while (reader.MoveToNextAttribute())
                                    {
                                        if (reader.Name == "name")
                                        {
                                            lastSpriteReaded = reader.Value.ToUpper();
                                        }
                                    }

									
                                    output.WriteLine("\n\t\tpublic const int SPR_" + lastSpriteReaded + " = " + (index++) + ";");

                                }

								string packNombre = "";

								if (reader.Name == "animpak")
								{
									packCount++;
									reader.MoveToAttribute("name");
									if (reader.Name == "name")
									{
										packNombre = reader.Value.Trim();
									}

									while (reader.Read() && !(reader.NodeType == XmlNodeType.EndElement && reader.Name == "animpak"))
									{
										if (reader.NodeType == XmlNodeType.Element)
										{
											if (reader.Name == "animacion")
											{
												while (reader.MoveToNextAttribute())
												{
													if (reader.Name == "name")
													{
														output.WriteLine("\t\tpublic const int SPR_ANIM_" + lastSpriteReaded + "_" + packNombre.ToUpper()+ "_" + reader.Value.ToUpper() + " = " + (subIndex++) + ";");
													}
												}

											}
										
										}
										
										
									}
								
								}

                               
                            }
							
                        }
						output.WriteLine("\t\tpublic const int SPR_" + lastSpriteReaded + "_PACK_COUNT = " + packCount + ";");
                        output.WriteLine("\n\t\tpublic const int SPR_COUNT = " + index + ";");
                    }



                                       //leo los sprites
                    if (reader.Name == "anims")
                    {
                        index = 0;
                        output.WriteLine("\n\n\t\t//---------------\n\t\t//Anims Ids");
                        while (reader.Read() && !(reader.NodeType == XmlNodeType.EndElement && reader.Name == "anims"))
                        {
                            if (reader.NodeType == XmlNodeType.Element)
                            {
                                if (reader.Name == "animacion")
                                {
                                    while (reader.MoveToNextAttribute())
                                    {
                                        if (reader.Name == "name")
                                        {
                                            output.WriteLine("\t\tpublic const int ANIM_" + reader.Value.ToUpper() + " = " + (index++) + ";");
                                        }
                                    }
                                    
                                }
                            }
                        }
                        output.WriteLine("\n\t\tpublic const int ANIM_COUNT = " + index + ";");
                    }




                    //leo los sonidos
                    if (reader.Name == "sonidos")
                    {
                        output.WriteLine("\n\n\t\t//---------------\n\t\t//Sound Ids\n");
                        index = 0;
                        bool readingMusic = false;
                        lastWritten = 0;

                        while (reader.Read() && !(reader.NodeType == XmlNodeType.EndElement && reader.Name == "sonidos"))
                        {
                            if (reader.NodeType == XmlNodeType.Element)
                            {

                                if (reader.Name == "musica")
                                {
                                    readingMusic = true;
                                }
                                else if (reader.Name == "sfx")
                                {
                                    output.WriteLine("\t\tpublic const int SND_COUNT = " + index + ";\n");
                                    lastWritten = index;

                                    readingMusic = false;
                                }
                                else if (reader.Name != "sonidos")
                                {
                                    output.WriteLine("\t\tpublic const int " + (readingMusic ? "SND_" : "SFX_") + reader.Name.ToUpper() + " = " + (index++) + ";");
                                }
                            }
                        }
                        output.WriteLine("\t\tpublic const int SFX_COUNT = " + (index - lastWritten) + ";");
                    }

                    // leo los escenarios
                    if (reader.Name == "escenarios" )
                    {
                        output.WriteLine("\n\n\t\t//---------------\n\t\t//scenario Ids\n");
                        index = 0;
                        bool readingTilesets = false;
                        lastWritten = 0;

                        while (reader.Read() && !(reader.NodeType == XmlNodeType.EndElement && reader.Name == "escenarios"))
                        {
                            if (reader.NodeType == XmlNodeType.Element)
                            {
                                if (reader.Name == "tilesets")
                                {
                                    readingTilesets = true;
                                }
                                else if (reader.Name == "mapas")
                                {
                                    output.WriteLine("\t\tpublic const int TLS_COUNT = " + index + ";\n");
                                    lastWritten = index;
                                    readingTilesets = false;
                                }
                                else if (reader.Name != "escenarios")
                                {
                                    output.WriteLine("\t\tpublic const int " + (readingTilesets ? "TLS_" : "MAP_") + reader.Name.ToUpper() + " = " + (index++) + ";");
                                 
                                }


                            }
                        }
                        output.WriteLine("\t\tpublic const int MAP_COUNT = " + (index - lastWritten) + ";");
                    }



                }
            }


            CrearTilesetIds(ref output);



            // cierro ambos archivos
            reader.Close();
            reader = null;
            output.WriteLine("\t}");
            output.WriteLine("}");
            output.Close();
        }


        private static void CrearTilesetIds(ref StreamWriter output)
        {

            //Leo el archivo de strings
            string path = Path.GetFullPath(Path.Combine(XML_PATH, RES_FILE));
            if (!File.Exists(path))
            {
                Console.WriteLine("Error -  no existe el archivo " + path);
            }
            XmlTextReader reader = new XmlTextReader(path);
            int numID = 0;
            string tilesetLeido = "";

            output.WriteLine("\n\n\t\t//---------------");
            output.WriteLine("\t\t//Ids de los Tiles;");
			List<string> lista = new List<string>();

            while (reader.Read())
            {
                if (reader.NodeType == XmlNodeType.Element && reader.Name == "tilesets")
                {
                    while (reader.Read() && reader.Name != "tilesets")
                    {
                        if (reader.NodeType == XmlNodeType.Element)
                        {
                            string tileset = reader.Name;
                            path = Path.GetFullPath(Path.Combine(XML_PATH, reader.ReadString()));
                            XmlTextReader lectorDeTileset = new XmlTextReader(path);

                            //Empiezo a leer el tileset para generar los ids
                            while (lectorDeTileset.Read())
                            {


                                if (lectorDeTileset.NodeType == XmlNodeType.Element)
                                {

                                    if (lectorDeTileset.Name == "tileset")
                                    {
                                        lectorDeTileset.MoveToAttribute("name");
                                        if (lectorDeTileset.Name == "name")
                                        {
                                            tilesetLeido = lectorDeTileset.Value;
                                            numID = 0;
                                        }
                                    }
                                    if (lectorDeTileset.Name == "tile")
                                    {
                                     
                                        while (lectorDeTileset.Read() && !(lectorDeTileset.NodeType == XmlNodeType.EndElement && lectorDeTileset.Name == "tile"))
                                        {
                                            if (lectorDeTileset.Name == "property")
                                            {
                                                lectorDeTileset.MoveToAttribute("name");
                                                if (lectorDeTileset.Value.ToUpper() == "ID" || lectorDeTileset.Value.ToUpper() == "UNIDAD")
                                                {
													lectorDeTileset.MoveToAttribute("value");
													if (!lista.Contains(lectorDeTileset.Value))
													{
                                                    output.WriteLine("\t\tpublic const int TILE_" + tilesetLeido.Trim().ToUpper() + "_ID_" + lectorDeTileset.Value + " = " + (numID++) + ";");
													lista.Add(lectorDeTileset.Value);
													}
                                                
                                                }

                                                //if (lectorDeTileset.Value.ToLower() == "unidad")
                                                //{
                                                //    lectorDeTileset.MoveToAttribute("value");
                                                //    output.WriteLine("\t\tpublic const int TILE_UNIDAD_ID_" + lectorDeTileset.Value + " = " + (numID++) + ";");

                                                //} 

                                                
                                            }
                                        }
                                    }
                                }
                            }
							lista.Clear();
                            lectorDeTileset.Close();
                            
                        }
                    }
                }
            }
        }

    }
}
