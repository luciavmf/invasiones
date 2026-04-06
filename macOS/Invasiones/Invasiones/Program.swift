//
//  Program.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Programa.cs — global application constants.
//  Entry point is AppDelegate/GameScene on macOS; only constants here.
//

import Foundation

enum Program {

    static let DEFAULT_FPS: Int = 20

    static let DATA_PATH = "data"
    static let SCENARIOS_PATH = "escenarios"
    static let LEVEL_PATH = "nivel"
    static let ICON_PATH = "imagenes/icono.png"

    static let STRINGS_XML_FILE = "strings.xml"
    static let RESOURCES_XML_FILE = "res.xml"

    static let SCREEN_WIDTH: Int = 1024
    static let SCREEN_HEIGHT: Int = 768

#if DEBUG
    static let FULLSCREEN = false
#else
    static let FULLSCREEN = true
#endif
}
