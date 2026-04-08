//
//  Language.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 08.04.26.
//
//  Supported UI languages and user preference persistence.
//

import Foundation

enum Language: String, CaseIterable {
    case spanish = "es"
    case english = "en"
    case german  = "de"

    /// The strings JSON file for this language.
    var filename: String { "strings_\(rawValue).json" }

    /// The name of the language in its own language.
    var displayName: String {
        switch self {
        case .spanish: return "Español"
        case .english: return "English"
        case .german:  return "Deutsch"
        }
    }

    /// The next language in the cycle.
    var next: Language {
        let all = Language.allCases
        let i = all.firstIndex(of: self)!
        return all[(i + 1) % all.count]
    }

    /// The currently selected language (resets to Spanish on each launch).
    static var current: Language = .spanish
}
