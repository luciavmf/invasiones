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

enum ResourcePath {
    static let dataPath = "data"
    static let scenatiosPath = "escenarios"
    static let levelPath = "nivel"
    static let iconPath = "imagenes/icono.png"

    static let stringsPath = "strings.xml"
    static let resourcesPath = "res.xml"
}

enum ScreenSize {
    static let width: Int = 1024
    static let height: Int = 768
}

enum Program {

    static let DEFAULT_FPS: Int = 20

#if DEBUG
    static let FULLSCREEN = false
#else
    static let FULLSCREEN = true
#endif
}
