// Debug/Log.swift
// Puerto de Log.cs — singleton de logging con niveles Debug/Info/Warn/Error.
// En DEBUG escribe a consola y a output.log; en Release no hace nada.

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

    // MARK: - Declaraciones
    private static var s_habilitado = true

#if DEBUG
    private let m_nombreDeArchivo = "output.log"
    private var m_archivoEscritor: FileHandle?
#endif

    // MARK: - Constructor (privado — singleton)
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

    // MARK: - Metodos
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
