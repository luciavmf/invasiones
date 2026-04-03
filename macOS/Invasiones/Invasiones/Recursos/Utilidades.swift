// Recursos/Utilidades.swift
// Puerto de Utilidades.cs — resolución de paths dentro del bundle de la aplicación.
// En macOS/iOS los assets se incluyen en el bundle; Bundle.main reemplaza las rutas relativas de Windows.

import Foundation

enum Utilidades {

    /// Devuelve el path completo del recurso dado su nombre relativo.
    /// Primero busca en el bundle principal (carpeta raíz), luego con subdirectorio "data".
    static func obtenerPath(_ nombre: String) -> String? {
        guard !nombre.isEmpty else {
            Log.Instancia.advertir("ObtenerPath: nombre de archivo no válido")
            return nil
        }

        // Descomponer en nombre base + extensión para usar Bundle.main.path(forResource:ofType:)
        let url = URL(fileURLWithPath: nombre)
        let base = url.deletingPathExtension().path
        let ext  = url.pathExtension

        // 1. Búsqueda directa en el bundle (incluye subdirectorios copiados como folder reference)
        if let path = Bundle.main.path(forResource: base, ofType: ext.isEmpty ? nil : ext) {
            return path
        }

        // 2. Búsqueda en subdirectorio "data" (para cuando los assets viven en data/)
        let enData = "data/" + nombre
        let urlData = URL(fileURLWithPath: enData)
        let baseData = urlData.deletingPathExtension().path
        if let path = Bundle.main.path(forResource: baseData, ofType: ext.isEmpty ? nil : ext) {
            return path
        }

        // 3. Búsqueda en el resourcePath del bundle (útil durante desarrollo con folder references)
        if let resourcePath = Bundle.main.resourcePath {
            let fullPath = (resourcePath as NSString).appendingPathComponent(nombre)
            if FileManager.default.fileExists(atPath: fullPath) {
                return fullPath
            }
            let fullPathData = (resourcePath as NSString).appendingPathComponent("data/" + nombre)
            if FileManager.default.fileExists(atPath: fullPathData) {
                return fullPathData
            }
        }

        Log.Instancia.advertir("ObtenerPath: no existe el archivo \"\(nombre)\"")
        return nil
    }

    /// Crea un path en el directorio temporal — para archivos generados en runtime (ej: output.log).
    static func crearPath(_ nombre: String) -> String {
        return (NSTemporaryDirectory() as NSString).appendingPathComponent(nombre)
    }
}
