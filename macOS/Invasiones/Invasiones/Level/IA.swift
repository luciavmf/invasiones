//
//  IA.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of IA.cs — artificial intelligence for enemy groups.
//

import Foundation

/// Artificial intelligence controller for enemy groups.
/// Loads scripted movement orders from an XML file and feeds them to the group one at a time.
class IA {

    // MARK: - Private class
    /// Contains the ordered stack of commands for a single battle phase.
    private class Battle {
        var commands: [Command] = []  // LIFO via popLast
    }

    // MARK: - Declarations
    /// All battles this AI has scripted orders for.
    private var battles: [Battle]
    /// The total number of battles loaded.
    private var battleCount: Int = 0
    /// The index of the battle whose commands are currently being issued.
    private var currentBattle: Int = 0

    // MARK: - Initializer
    init() {
        battles = Array(repeating: Battle(), count: Level.Constants.maxBattles)
    }

    // MARK: - Loading

    /// Loads the AI order script for the enemy group placed at tile (x, y) in the given level.
    /// - Parameters:
    ///   - x: The tile column where the group is placed.
    ///   - y: The tile row where the group is placed.
    ///   - levelIndex: The level number, used to locate the script file.
    func load(x: Int, y: Int, levelIndex: Int) {
        let pathStr = ResourcePath.levelPath + "/orden_nv\(levelIndex)_\(x)_\(y).xml"
        guard let path = Utils.getPath(pathStr) else {
            Log.shared.debug("IA: No se encuentra el archivo: \(pathStr)")
            return
        }
        battleCount = 0

        guard let parser = XMLParser(contentsOf: URL(fileURLWithPath: path)) else { return }
        let d = IAXMLDelegate()
        parser.delegate = d
        parser.parse()
        withExtendedLifetime(d) {}

        for (i, commands) in d.batallas.enumerated() {
            if i < battles.count {
                battles[i].commands = commands.reversed()
                battleCount += 1
            }
        }
        currentBattle = 0
    }

    // MARK: - Methods

    /// Returns the next scripted command to execute, advancing to the next battle when the current one runs out.
    /// - Returns: The next command, or `nil` if all battles are complete.
    func nextCommand() -> Command? {
        guard currentBattle < battleCount else {
            Log.shared.debug("IA: No hay mas batallas.")
            return nil
        }

        if battles[currentBattle].commands.isEmpty {
            Log.shared.debug("IA: Paso a la siguiente battle.")
            currentBattle += 1
            if currentBattle >= battleCount {
                Log.shared.debug("IA: No hay mas batallas.")
                return nil
            }
        }

        return battles[currentBattle].commands.popLast()
    }
}

// MARK: - XML parser

private class IAXMLDelegate: NSObject, XMLParserDelegate {
    var batallas: [[Command]] = []
    private var current: [Command] = []
    private var inBattle = false

    func parser(_ parser: XMLParser, didStartElement name: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes a: [String: String]) {
        if name == "battle" {
            inBattle = true
            current = []
        } else if inBattle {
            let iVal = (Int(a["i"] ?? "0") ?? 0) << 1
            let jVal = (Int(a["j"] ?? "0") ?? 0) << 1
            let type: Command.Kind
            switch name {
            case "llegar": type = .move
            case "patrol": type = .patrol
            default: type = .invalid
            }
            if type != .invalid {
                current.append(Command(type, iVal, jVal))
            }
        }
    }

    func parser(_ parser: XMLParser, didEndElement name: String,
                namespaceURI: String?, qualifiedName: String?) {
        if name == "battle" {
            batallas.append(current.reversed())
            current = []
            inBattle = false
        }
    }
}
