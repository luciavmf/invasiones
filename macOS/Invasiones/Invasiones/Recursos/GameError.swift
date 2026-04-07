//
//  GameError.swift
//  Invasiones

import Foundation

/// Errors thrown during resource and map loading.
enum GameError: Error, LocalizedError {
    case fileNotFound(String)
    case parsingFailed(String)
    case invalidResource(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):      return "File not found: \(path)"
        case .parsingFailed(let detail):   return "Parsing failed: \(detail)"
        case .invalidResource(let detail): return "Invalid resource: \(detail)"
        }
    }
}
