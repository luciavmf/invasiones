//
//  Log.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Log.cs — logging singleton with Debug/Info/Warn/Error levels.
//  In DEBUG writes to console and output.log; in Release does nothing.
//

import Foundation

class Log {

    // MARK: - Singleton
    private static var s_instancia: Log?

    static var Instancia: Log {
        if s_instancia == nil {
            s_instancia = Log()
        }
        return s_instancia!
    }

    // MARK: - Declarations
    private static var s_habilitado = true

#if DEBUG
    private let m_nombreDeArchivo = "output.log"
    private var m_archivoEscritor: FileHandle?
#endif

    // MARK: - Initializer (private — singleton)
    private init() {
#if DEBUG
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(m_nombreDeArchivo)
        FileManager.default.createFile(atPath: url.path, contents: nil)
        m_archivoEscritor = try? FileHandle(forWritingTo: url)
        m_archivoEscritor?.seekToEndOfFile()
#endif
    }

    deinit {
        dispose()
    }

    func dispose() {
#if DEBUG
        m_archivoEscritor?.closeFile()
        m_archivoEscritor = nil
#endif
        Log.s_instancia = nil
    }

    // MARK: - Methods
    private func loguear(_ nivel: String, _ mensaje: String) {
        guard Log.s_habilitado else { return }
#if DEBUG
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        let linea = "[\(timestamp)] \(nivel) - \(mensaje)"
        print(linea)
        if let data = (linea + "\n").data(using: .utf8) {
            m_archivoEscritor?.write(data)
        }
#endif
    }

    func debug(_ mensaje: String)    { loguear("DEBUG", mensaje) }
    func informar(_ mensaje: String) { loguear("INFO",  mensaje) }
    func advertir(_ mensaje: String) { loguear("WARN",  mensaje) }
    func error(_ mensaje: String)    { loguear("ERROR", mensaje) }
    func error(_ error: Error)       { self.error(error.localizedDescription) }
}
