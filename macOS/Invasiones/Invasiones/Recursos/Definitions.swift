//
//  Definitions.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Definiciones.cs — global game constants.
//

import Foundation

enum Definitions {

    // MARK: - Cheats
    static let CHEATS_ENABLED = true

    // MARK: - Colors (RGB hex)
    static let COLOR_GRAY        = 0xC8C8C8
    static let COLOR_RED        = 0xFF0000
    static let COLOR_BLACK       = 0x000000
    static let COLOR_WHITE      = 0xFFFFFF
    static let COLOR_GREEN       = 0x00FF00
    static let COLOR_BLUE        = 0x0000FF
    static let COLOR_CYAN     = 0x00FFFF
    static let COLOR_MAGENTA     = 0xFF00FF
    static let COLOR_TRANSPARENT = COLOR_MAGENTA

    // MARK: - Layout
    static let OBJECTIVES_OFFSET   = 7
    static let OBJECTIVES_WIDTH    = 410
    static let OBJECTIVES_HEIGHT     = 22
    static let LINE_SPACING = 5

    static let COLOR_LOADING   = COLOR_BLUE
    static let COLOR_TITLE    = COLOR_WHITE
    static let COLOR_OBJECTIVES = COLOR_BLACK

    static let OBJECTIVE_SHOW_START_COUNT = 50
    static let OBJECTIVES_BUTTON_Y              = 510
    static let MAIN_MENU_Y_OFFSET        = 50
    static let OBJECTIVES_BORDER                = 100
    static let LOADING_Y                     = 200
    static let HELP_TEXT_Y                  = 200
    static let HELP_ITEM_Y             = 150

    /// Y position for all titles.
    static let TITLE_Y          = 30
    static let GAME_PAUSED_Y   = -200

    // MARK: - GUI
    static let GUI_COLOR_MENUS    = COLOR_BLACK
    static let GUI_COLOR_SELECTION = COLOR_RED
    static let GUI_COLOR_TEXT    = COLOR_WHITE
    static let GUI_ALPHA          = 128

    static let OBJECTIVES_ALPHA    = GUI_ALPHA
    static let CONFIRMATION_ALPHA = 128
    static let CONFIRMATION_WIDTH = 350
    static let CONFIRMATION_HEIGHT  = 150

    static let TIPS_ALPHA = 100
    static let TIPS_WIDTH = 450
    static let TIPS_HEIGHT  = 100

    static let PRESS_CONTINUE_Y = 200
    static let PAGES_PER_INTRO         = 3
    static let TOTAL_TICKS_TO_OBJECTIVE = 50

    // MARK: - Fonts
    enum FNT: Int {
        case SANS12 = 0
        case SANS14
        case SANS18
        case SANS20
        case SANS24
        case SANS28
        case LBLACK12
        case LBLACK14
        case LBLACK18
        case LBLACK20
        case LBLACK28
        case TOTAL
    }

    static let FONT_OBJECTIVES_TITLE       = FNT.LBLACK28.rawValue
    static let FONT_TITLE                 = FNT.LBLACK28.rawValue
    static let FONT_HELP_TITLE           = FNT.SANS24.rawValue
    static let FONT_HELP                  = FNT.SANS18.rawValue
    static let FONT_MENU                   = FNT.SANS20.rawValue
    static let FONT_BUTTON                  = FNT.SANS14.rawValue
    static let FONT_OBJECTIVES_REMINDER = FNT.SANS14.rawValue
    static let FONT_OBJECTIVES              = FNT.SANS20.rawValue
    static let FONT_WIN                   = FNT.LBLACK28.rawValue

    static let COLOR_OBJECTIVES_FONT = COLOR_WHITE
    static let COLOR_WIN_TEXT       = COLOR_WHITE

    // MARK: - Sprite directions (8 directions)
    enum DIRECTION: Int {
        case N = 0, NE, E, SE, S, SO, O, NO
        static let DIRECTION_COUNT = 8
    }
}
