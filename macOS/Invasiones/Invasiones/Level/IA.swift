//
//  IA.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of IA.cs — artificial intelligence for enemy groups.
//

import Foundation

class IA {

    // MARK: - Private class
    private class Batalla {
        var m_commands: [Command] = []  // LIFO via popLast
    }

    // MARK: - Declarations
    private var m_battles:           [Batalla]
    private var m_battleCount: Int = 0
    private var m_currentBattle:   Int = 0

    // MARK: - Initializer
    init() {
        m_battles = Array(repeating: Batalla(), count: Level.MAX_BATTLES)
    }

    // MARK: - Loading

    func load(_ x: Int, _ y: Int, _ levelIndex: Int) {
        let pathStr = Program.LEVEL_PATH + "/orden_nv\(levelIndex)_\(x)_\(y).xml"
        guard let path = Utils.getPath(pathStr) else {
            Log.shared.debug("IA: No se encuentra el archivo: \(pathStr)")
            return
        }
        m_battleCount = 0

        guard let parser = XMLParser(contentsOf: URL(fileURLWithPath: path)) else { return }
        let d = IAXMLDelegate()
        parser.delegate = d
        parser.parse()
        withExtendedLifetime(d) {}

        for (i, commands) in d.batallas.enumerated() {
            if i < m_battles.count {
                m_battles[i].m_commands = commands.reversed()
                m_battleCount += 1
            }
        }
        m_currentBattle = 0
    }

    // MARK: - Methods

    func nextCommand() -> Command? {
        guard m_currentBattle < m_battleCount else {
            Log.shared.debug("IA: No hay mas batallas.")
            return nil
        }

        if m_battles[m_currentBattle].m_commands.isEmpty {
            Log.shared.debug("IA: Paso a la siguiente battle.")
            m_currentBattle += 1
            if m_currentBattle >= m_battleCount {
                Log.shared.debug("IA: No hay mas batallas.")
                return nil
            }
        }

        return m_battles[m_currentBattle].m_commands.popLast()
    }
}

// MARK: - XML parser

private class IAXMLDelegate: NSObject, XMLParserDelegate {
    var batallas:   [[Command]] = []
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
            let type: Command.TYPE
            switch name {
            case "llegar":    type = .MOVE
            case "patrol": type = .PATROL
            default:          type = .INVALID
            }
            if type != .INVALID {
                current.append(Command(type, iVal, jVal))
            }
        }
    }

    func parser(_ parser: XMLParser, didEndElement name: String,
                namespaceURI: String?, qualifiedName: String?) {
        if name == "battle" {
            batallas.append(current.reversed())
            current   = []
            inBattle = false
        }
    }
}
