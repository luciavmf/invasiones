//
//  GameText.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Texto.cs — loads and caches localised strings from strings.json.
//

import Foundation

/// Loads and caches all localised strings from strings.json.
/// All strings are cached in a static array indexed by the `Res.STR_*` constants.
/// Tips are stored separately in `GameText.tips` and are not part of the indexed table.
enum GameText {

    // MARK: - Key order (must match Res.STR_* index values)
    private static let keyOrder: [String] = [
        "sdl_init_failed",                  // 0
        "window_caption",                   // 1
        "fatal_error_caption",              // 2
        "press_to_continue",                // 3
        "loading",                          // 4
        "next",                             // 5
        "back",                             // 6
        "you_won",                          // 7
        "you_lost",                         // 8
        "play_again",                       // 9
        "objectives",                       // 10
        "accept",                           // 11
        "continue",                         // 12
        "menu_main",                        // 13
        "menu_continue",                    // 14
        "menu_new_game",                    // 15
        "menu_load_game",                   // 16
        "menu_options",                     // 17
        "menu_credits",                     // 18
        "menu_help",                        // 19
        "menu_exit",                        // 20
        "menu_save",                        // 21
        "menu_restart",                     // 22
        "btn_back",                         // 23
        "btn_game_menu",                    // 24
        "game_paused",                      // 25
        "unit",                             // 26
        "resistance_points",                // 27
        "range",                            // 28
        "attack_points",                    // 29
        "visibility",                       // 30
        "aim",                              // 31
        "speed",                            // 32
        "exit_confirmation",                // 33
        "yes",                              // 34
        "no",                               // 35
        "enter_name",                       // 36
        "done",                             // 37
        "credits_programming",              // 38
        "credits_programmer_1",             // 39
        "credits_level_design",             // 40
        "credits_level_designer_1",         // 41
        "objective_battle_1_1",             // 42
        "objective_battle_2_1",             // 43
        "objective_battle_3_1",             // 44
        "objective_battle_4_1",             // 45
        "battle_1",                         // 46
        "battle_1_2",                       // 47
        "battle_1_objective_3",             // 48
        "battle_2",                         // 49
        "battle_2_2",                       // 50
        "battle_2_objective_3",             // 51
        "battle_3",                         // 52
        "battle_3_2",                       // 53
        "battle_3_objective_3",             // 54
        "battle_4",                         // 55
        "battle_4_2",                       // 56
        "battle_4_objective_3",             // 57
        "aftermath",                        // 58
        "aftermath_1",                      // 59
        "aftermath_2",                      // 60
        "aftermath_3",                      // 61
        "help_select_01",                   // 62
        "help_select_02",                   // 63
        "help_move_01",                     // 64
        "help_move_02",                     // 65
        "help_attack_01",                   // 66
        "help_attack_02",                   // 67
        "help_objective_01",                // 68
        "help_objective_02",                // 69
        "help_scroll_01",                   // 70
        "help_scroll_02",                   // 71
        "help_hud_01",                      // 72
        "help_hud_02",                      // 73
        "help_heal_01",                     // 74
        "help_heal_02",                     // 75
        "help_tips_01",                     // 76
        "help_tips_02",                     // 77
        "help_win_01",                      // 78
        "help_win_02",                      // 79
        "tip_00",                           // 80  ("Tip!" button label)
        "language",                         // 81
        "language_label",                   // 82
        "sound_label",                      // 83
    ]

    // MARK: - Static storage
    private static var s_strings: [String]?
    private static var s_tips: [String] = []

    // MARK: - Load
    static func loadStrings() throws {
        let filename = Language.current.filename
        guard let path = Utils.getPath(filename) else {
            throw GameError.fileNotFound("No se encuentra el archivo \(filename).")
        }
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let raw: [String: Any]
        do {
            raw = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        } catch {
            throw GameError.parsingFailed("GameText: failed to parse \(filename): \(error).")
        }
        let dict = raw.compactMapValues { $0 as? String }
        s_strings = keyOrder.map { dict[$0] ?? "" }
        s_tips = raw["tips"] as? [String] ?? []
    }

    // MARK: - Access

    /// All indexed strings, accessed via Res.STR_* constants.
    static var Strings: [String] {
        if s_strings == nil { try? loadStrings() }
        return s_strings ?? []
    }

    /// All gameplay tips for the current language. Pick with randomElement().
    static var tips: [String] {
        if s_strings == nil { try? loadStrings() }
        return s_tips
    }
}
