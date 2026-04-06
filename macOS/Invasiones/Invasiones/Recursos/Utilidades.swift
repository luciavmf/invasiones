//
//  Utilidades.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Utilidades.cs — resolves asset paths within the application bundle.
//  Bundle.main replaces the Windows relative paths from the original.
//

import Foundation

enum Utilidades {

    /// Returns the full path for a resource given its relative name.
    /// Normalizes Windows path separators (\) to Unix (/) before searching.
    /// Searches first directly in the bundle, then under the "data/" subdirectory.
    static func obtenerPath(_ nombre: String) -> String? {
        guard !nombre.isEmpty else {
            Log.Instancia.advertir("ObtenerPath: nombre de archivo no válido")
            return nil
        }

        // Normalize Windows → Unix separators
        let normalizado = nombre.replacingOccurrences(of: "\\", with: "/")

        // If it's already an absolute path that exists, return it directly.
        if normalizado.hasPrefix("/") {
            if FileManager.default.fileExists(atPath: normalizado) { return normalizado }
            Log.Instancia.advertir("ObtenerPath: no existe el archivo \"\(normalizado)\"")
            return nil
        }

        // Search in the bundle's resourcePath (the most reliable approach with folder references)
        if let resourcePath = Bundle.main.resourcePath {
            // 1. Directly under the bundle
            let fullPath = (resourcePath as NSString).appendingPathComponent(normalizado)
            if FileManager.default.fileExists(atPath: fullPath) {
                return fullPath
            }
            // 2. Under data/
            let fullPathData = (resourcePath as NSString).appendingPathComponent("data/" + normalizado)
            if FileManager.default.fileExists(atPath: fullPathData) {
                return fullPathData
            }
        }

        Log.Instancia.advertir("ObtenerPath: no existe el archivo \"\(normalizado)\"")
        return nil
    }

    /// Creates a path in the temporary directory — for runtime-generated files (e.g. output.log).
    static func crearPath(_ nombre: String) -> String {
        return (NSTemporaryDirectory() as NSString).appendingPathComponent(nombre)
    }
}
