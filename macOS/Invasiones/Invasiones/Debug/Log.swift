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
    private static var instance: Log?

    static var shared: Log {
        if instance == nil {
            instance = Log()
        }
        return instance!
    }

    // MARK: - Declarations
    private static var enabled = true

#if DEBUG
    private let fileName = "output.log"
    private var fileWriter: FileHandle?
#endif

    // MARK: - Initializer (private — singleton)
    private init() {
#if DEBUG
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        FileManager.default.createFile(atPath: url.path, contents: nil)
        fileWriter = try? FileHandle(forWritingTo: url)
        fileWriter?.seekToEndOfFile()
#endif
    }

    deinit {
        dispose()
    }

    func dispose() {
#if DEBUG
        fileWriter?.closeFile()
        fileWriter = nil
#endif
        Log.instance = nil
    }

    // MARK: - Methods
    private func log(_ level: String, _ message: String) {
        guard Log.enabled else { return }
#if DEBUG
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        let line = "[\(timestamp)] \(level) - \(message)"
        print(line)
        if let data = (line + "\n").data(using: .utf8) {
            fileWriter?.write(data)
        }
#endif
    }

    func debug(_ message: String) {
        log("DEBUG", message)
    }

    func info(_ message: String) {
        log("INFO",  message)
    }

    func warn(_ message: String) {
        log("WARN",  message)
    }

    func error(_ message: String) {
        log("ERROR", message)
    }

    func error(_ error: Error) {
        self.error(error.localizedDescription)
    }
}
