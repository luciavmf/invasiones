//
//  Definitions.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Definiciones.cs — global game constants.
//

import Foundation

/// Font slot indices into `ResourceManager.fonts`.
enum FontIndex: Int {
    case sans12 = 0
    case sans14
    case sans18
    case sans20
    case sans24
    case sans28
    case lblack12
    case lblack14
    case lblack18
    case lblack20
    case lblack28
    case total
}

/// Eight compass directions used for unit sprite animation.
enum Direction: Int, CaseIterable {
    case north = 0, northEast, east, southEast, south, southWest, west, northWest
}

/// RGB hex colour constants used by the `Video` drawing API.
enum GameColor {
    static let gray        = 0xC8C8C8
    static let red         = 0xFF0000
    static let black       = 0x000000
    static let white       = 0xFFFFFF
    static let green       = 0x00FF00
    static let blue        = 0x0000FF
    static let cyan        = 0x00FFFF
    static let magenta     = 0xFF00FF
    static let transparent = magenta
}

/// Colors used in the UI
enum Theme {
    static let menus = GameColor.black
    static let selection = GameColor.red
    static let buttonHover = GameColor.black
    static let text = GameColor.white
    static let alpha = 128
    static let title = GameColor.white
    static let objectivesText = GameColor.black
}

/// Fonts used in the ui
enum FontConstants {
    static let titleFont = FontIndex.lblack28.rawValue
    static let helpTitleFont = FontIndex.sans24.rawValue
    static let helpFont = FontIndex.sans18.rawValue
    static let menuFont = FontIndex.sans20.rawValue
    static let buttonFont = FontIndex.sans14.rawValue
    static let objectivesReminderFont = FontIndex.sans14.rawValue
    static let objectivesFont = FontIndex.sans20.rawValue
}

/// Layout
enum Layout {
    static let objectivesOffset = 7
    static let objectivesHeight = 22
    /// Y position for all titles.
    static let titleYPosition = 30
}
