//
//  Level.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Nivel.cs — manages battles and objectives for a level.
//

import Foundation

class Level {

    // MARK: - Constants
    static let MAX_BATTLES = 5

    // MARK: - Private class
    private class Batalla {
        var m_objetivos:          [Objective] = []  // LIFO: popLast
        var objectiveCount:  Int = 0
    }

    // MARK: - Declarations
    private var m_battles:      [Batalla?]
    private var m_currentBattle:       Int = 0
    private var m_battleCount:     Int = 0
    private var m_currentObjective:      Int = 0
    private var m_completedObjectiveCount: Int = -1

    // MARK: - Properties
    var currentObjectiveIndex:            Int { m_currentObjective }
    var currentBattleIndex:             Int { m_currentBattle }
    var battleCount:           Int { m_battleCount }
    var completedObjectiveCount: Int { m_completedObjectiveCount }

    var currentObjectiveCount: Int {
        guard m_currentBattle < m_battles.count,
              let b = m_battles[m_currentBattle] else { return 0 }
        return b.objectiveCount
    }

    // MARK: - Initializer
    init() {
        m_battles = Array(repeating: nil, count: Level.MAX_BATTLES)
        m_currentBattle  = 0
        m_battleCount = 0
        m_completedObjectiveCount = -1
    }

    // MARK: - Loading

    func load(_ levelIndex: Int) {
        let pathStr = Program.LEVEL_PATH + "/nivel_\(levelIndex).xml"
        guard let path = Utils.getPath(pathStr) else {
            Log.shared.debug("No se pueden load los objetivos. No se encuentra el archivo: \(pathStr)")
            return
        }
        m_currentBattle   = 0
        m_currentObjective  = 0
        m_battleCount = 0

        guard let parser = XMLParser(contentsOf: URL(fileURLWithPath: path)) else { return }
        let d = NivelXMLDelegate()
        parser.delegate = d
        parser.parse()
        withExtendedLifetime(d) {}

        for (i, battle) in d.batallas.enumerated() {
            if i < m_battles.count {
                let b = Batalla()
                b.m_objetivos = battle.objetivos.reversed()  // reversal puts first-in at last (pop = LIFO)
                b.objectiveCount = battle.objetivos.count
                m_battles[i] = b
                m_battleCount += 1
            }
        }
    }

    // MARK: - Methods

    /// Returns the next objective to complete, or nil if the level has been won.
    func nextObjective() -> Objective? {
        m_currentObjective += 1
        m_completedObjectiveCount += 1

        guard m_currentBattle < m_battles.count,
              let battle = m_battles[m_currentBattle] else { return nil }

        if battle.m_objetivos.isEmpty {
            m_currentBattle += 1
            m_currentObjective = 0
            Log.shared.debug("Paso a la siguiente battle.")
            if m_currentBattle >= m_battleCount {
                Log.shared.debug("No hay mas objetivos — gane!!")
                return nil
            }
        }

        guard m_currentBattle < m_battles.count,
              let b2 = m_battles[m_currentBattle],
              !b2.m_objetivos.isEmpty else { return nil }

        return b2.m_objetivos.removeLast()
    }
}

// MARK: - XML parser

private class NivelXMLDelegate: NSObject, XMLParserDelegate {

    struct BatallaData { var objetivos: [Objective] = [] }
    var batallas: [BatallaData] = []

    private var inBattle  = false
    private var inObjective = false
    private var currentObj:  Objective?
    private var currentCommands:  [Command]  = []

    func parser(_ parser: XMLParser, didStartElement name: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes a: [String: String]) {
        switch name {
        case "batalla":
            inBattle = true
            batallas.append(BatallaData())
        case "objetivo":
            let imgPath = a["imagen"]
            currentObj = Objective(pathImagen: imgPath)
            currentCommands = []
            inObjective = true
        case "tomar", "llegar", "trigger", "matar":
            guard inObjective else { return }
            let iVal = (Int(a["i"] ?? "0") ?? 0) << 1
            let jVal = (Int(a["j"] ?? "0") ?? 0) << 1
            let type: Command.TYPE
            switch name {
            case "tomar":   type = .TAKE_OBJECT
            case "llegar":  type = .MOVE
            case "trigger": type = .TRIGGER
            case "matar":   type = .KILL
            default:        type = .INVALID
            }
            let ord: Command
            if type == .TAKE_OBJECT, let img = a["imagen"] {
                ord = Command(type, iVal, jVal, img)
            } else if type == .TRIGGER, let t = a["tipo"] {
                let animIdx: Int
                switch t {
                case "fuego1": animIdx = Res.ANIM_FUEGO_1
                case "fuego2": animIdx = Res.ANIM_FUEGO_2
                default: animIdx = -1
                }
                if animIdx >= 0,
                   let anim = ResourceManager.shared.animations[animIdx] {
                    let animObj = AnimObject(Animation(copia: anim), iVal, jVal)
                    ord = Command(type, iVal, jVal, animObj)
                } else {
                    ord = Command(type, iVal, jVal)
                }
            } else if type == .KILL, let anchoStr = a["ancho"] {
                ord = Command(type, iVal, jVal, (Int(anchoStr) ?? 0) << 1)
            } else {
                ord = Command(type, iVal, jVal)
            }
            currentCommands.append(ord)
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement name: String,
                namespaceURI: String?, qualifiedName: String?) {
        if name == "objetivo", let obj = currentObj {
            obj.commands = currentCommands.reversed()
            batallas[batallas.count - 1].objetivos.append(obj)
            currentObj  = nil
            inObjective = false
        } else if name == "batalla" {
            inBattle = false
        }
    }
}
