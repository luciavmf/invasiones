// Recursos/Utilidades.swift
// Puerto de Utilidades.cs — resolución de paths dentro del bundle de la aplicación.
// En macOS/iOS los assets se incluyen en el bundle; Bundle.main reemplaza las rutas relativas de Windows.

import Foundation

enum Utilidades {

    /// Devuelve el path completo del recurso dado su nombre relativo.
    /// Normaliza separadores de Windows (\) a Unix (/) antes de buscar.
    /// Busca primero en el bundle directo, luego bajo el subdirectorio "data/".
    static func obtenerPath(_ nombre: String) -> String? {
        guard !nombre.isEmpty else {
            Log.Instancia.advertir("ObtenerPath: nombre de archivo no válido")
            return nil
        }

        // Normalizar separadores Windows → Unix
        let normalizado = nombre.replacingOccurrences(of: "\\", with: "/")

        // Búsqueda en el resourcePath del bundle (la forma más fiable con folder references)
        if let resourcePath = Bundle.main.resourcePath {
            // 1. Directo bajo el bundle
            let fullPath = (resourcePath as NSString).appendingPathComponent(normalizado)
            if FileManager.default.fileExists(atPath: fullPath) {
                return fullPath
            }
            // 2. Bajo data/
            let fullPathData = (resourcePath as NSString).appendingPathComponent("data/" + normalizado)
            if FileManager.default.fileExists(atPath: fullPathData) {
                return fullPathData
            }
        }

        Log.Instancia.advertir("ObtenerPath: no existe el archivo \"\(normalizado)\"")
        return nil
    }

    /// Crea un path en el directorio temporal — para archivos generados en runtime (ej: output.log).
    static func crearPath(_ nombre: String) -> String {
        return (NSTemporaryDirectory() as NSString).appendingPathComponent(nombre)
    }
}
