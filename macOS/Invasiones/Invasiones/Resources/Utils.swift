//
//  Utils.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Utilidades.cs — resolves asset paths within the application bundle.
//  Bundle.main replaces the Windows relative paths from the original.
//

import Foundation

enum Utils {

    /// Returns the full path for a resource given its relative name.
    /// Normalizes Windows path separators (\) to Unix (/) before searching.
    /// Searches first directly in the bundle, then under the "data/" subdirectory.
    static func getPath(_ name: String) -> String? {
        guard !name.isEmpty else {
            Log.shared.warn("Utils.getPath: invalid file name")
            return nil
        }

        // Normalize Windows → Unix separators
        let normalized = name.replacingOccurrences(of: "\\", with: "/")

        // If it's already an absolute path that exists, return it directly.
        if normalized.hasPrefix("/") {
            if FileManager.default.fileExists(atPath: normalized) { return normalized }
            Log.shared.warn("Utils.getPath: file not found \"\(normalized)\"")
            return nil
        }

        // Search in the bundle's resourcePath (the most reliable approach with folder references)
        if let resourcePath = Bundle.main.resourcePath {
            // 1. Directly under the bundle
            let fullPath = (resourcePath as NSString).appendingPathComponent(normalized)
            if FileManager.default.fileExists(atPath: fullPath) {
                return fullPath
            }
            // 2. Under data/
            let fullPathData = (resourcePath as NSString).appendingPathComponent("data/" + normalized)
            if FileManager.default.fileExists(atPath: fullPathData) {
                return fullPathData
            }
        }

        Log.shared.warn("Utils.getPath: file not found \"\(normalized)\"")
        return nil
    }

    /// Creates a path in the temporary directory — for runtime-generated files (e.g. output.log).
    static func createPath(_ name: String) -> String {
        return (NSTemporaryDirectory() as NSString).appendingPathComponent(name)
    }
}
