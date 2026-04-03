// Programa.swift
// Puerto de Programa.cs — constantes globales de la aplicación.
// El punto de entrada es AppDelegate/GameScene en macOS; aquí sólo las constantes.

import Foundation

enum Programa {

    static let FPS_POR_DEFECTO: Int = 20

    static let PATH_DATA       = "data"
    static let PATH_ESCENARIOS = "escenarios"
    static let PATH_NIVEL      = "nivel"
    static let PATH_ICONO      = "imagenes/icono.png"

    static let ARCHIVO_XML_TEXTOS   = "strings.xml"
    static let ARCHIVO_XML_RECURSOS = "res.xml"

    static let ANCHO_DE_LA_PANTALLA: Int = 1024
    static let ALTO_DE_LA_PANTALLA:  Int = 768

#if DEBUG
    static let FULLSCREEN = false
#else
    static let FULLSCREEN = true
#endif
}
