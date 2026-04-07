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
enum Direction: Int {
    case north = 0, northEast, east, southEast, south, southWest, west, northWest
    static let count = 8
}

enum Definitions {

    // MARK: - Cheats
    static let CHEATS_ENABLED = true

    // MARK: - Colors (RGB hex)
    static let COLOR_GRAY = 0xC8C8C8
    static let COLOR_RED = 0xFF0000
    static let COLOR_BLACK = 0x000000
    static let COLOR_WHITE = 0xFFFFFF
    static let COLOR_GREEN = 0x00FF00
    static let COLOR_BLUE = 0x0000FF
    static let COLOR_CYAN = 0x00FFFF
    static let COLOR_MAGENTA = 0xFF00FF
    static let COLOR_TRANSPARENT = COLOR_MAGENTA

    // MARK: - Layout
    static let OBJECTIVES_OFFSET = 7
    static let OBJECTIVES_WIDTH = 410
    static let OBJECTIVES_HEIGHT = 22
    static let LINE_SPACING = 5

    static let COLOR_LOADING = COLOR_BLUE
    static let COLOR_TITLE = COLOR_WHITE
    static let COLOR_OBJECTIVES = COLOR_BLACK

    static let OBJECTIVE_SHOW_START_COUNT = 50
    static let OBJECTIVES_BUTTON_Y = 510
    static let MAIN_MENU_Y_OFFSET = 50
    static let OBJECTIVES_BORDER = 100
    static let LOADING_Y = 200
    static let HELP_TEXT_Y = 200
    static let HELP_ITEM_Y = 150

    /// Y position for all titles.
    static let TITLE_Y = 30
    static let GAME_PAUSED_Y = -200

    // MARK: - GUI
    static let GUI_COLOR_MENUS = COLOR_BLACK
    static let GUI_COLOR_SELECTION = COLOR_RED
    static let GUI_COLOR_TEXT = COLOR_WHITE
    static let GUI_ALPHA = 128

    static let OBJECTIVES_ALPHA = GUI_ALPHA
    static let CONFIRMATION_ALPHA = 128
    static let CONFIRMATION_WIDTH = 350
    static let CONFIRMATION_HEIGHT = 150

    static let TIPS_ALPHA = 100
    static let TIPS_WIDTH = 450
    static let TIPS_HEIGHT = 100

    static let PRESS_CONTINUE_Y = 200
    static let PAGES_PER_INTRO = 3
    static let TOTAL_TICKS_TO_OBJECTIVE = 50

    // MARK: - Fonts
    static let FONT_OBJECTIVES_TITLE = FontIndex.lblack28.rawValue
    static let FONT_TITLE = FontIndex.lblack28.rawValue
    static let FONT_HELP_TITLE = FontIndex.sans24.rawValue
    static let FONT_HELP = FontIndex.sans18.rawValue
    static let FONT_MENU = FontIndex.sans20.rawValue
    static let FONT_BUTTON = FontIndex.sans14.rawValue
    static let FONT_OBJECTIVES_REMINDER = FontIndex.sans14.rawValue
    static let FONT_OBJECTIVES = FontIndex.sans20.rawValue
    static let FONT_WIN = FontIndex.lblack28.rawValue

    static let COLOR_OBJECTIVES_FONT = COLOR_WHITE
    static let COLOR_WIN_TEXT = COLOR_WHITE
}
