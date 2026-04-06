//
//  Level.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Nivel.cs — manages battles and objectives for a level.
//

import Foundation

/// Manages the battles and objectives for a level, loaded from nivel_N.xml.
class Level {

    // MARK: - Constants
    /// The maximum number of battles a level can contain.
    static let MAX_BATTLES = 5

    // MARK: - Private class
    /// Contains the ordered stack of objectives for a single battle phase.
    private class Batalla {
        var objetivos: [Objective] = []  // LIFO: popLast
        /// The total number of objectives this battle originally had.
        var objectiveCount: Int = 0
    }

    // MARK: - Declarations
    /// All battles in the level.
    private var battles: [Batalla?]
    /// The index of the battle currently being played.
    private(set) var currentBattleIndex: Int = 0
    /// The total number of battles loaded for this level.
    private(set) var battleCount: Int = 0
    /// The index of the current objective within the current battle.
    private(set) var currentObjectiveIndex: Int = 0
    /// Running count of objectives completed so far (across all battles).
    private(set) var completedObjectiveCount: Int = -1

    // MARK: - Properties
    /// The number of objectives in the current battle.
    var currentObjectiveCount: Int {
        guard currentBattleIndex < battles.count,
              let b = battles[currentBattleIndex] else { return 0 }
        return b.objectiveCount
    }

    // MARK: - Initializer
    init() {
        battles = Array(repeating: nil, count: Level.MAX_BATTLES)
        currentBattleIndex = 0
        battleCount = 0
        completedObjectiveCount = -1
    }

    // MARK: - Loading

    /// Reads the level definition from nivel_{levelIndex}.xml and populates the battles array.
    /// - Parameter levelIndex: The level number to load.
    func load(_ levelIndex: Int) {
        let pathStr = Program.LEVEL_PATH + "/nivel_\(levelIndex).xml"
        guard let path = Utils.getPath(pathStr) else {
            Log.shared.debug("No se pueden load los objetivos. No se encuentra el archivo: \(pathStr)")
            return
        }
        currentBattleIndex = 0
        currentObjectiveIndex = 0
        battleCount = 0

        guard let parser = XMLParser(contentsOf: URL(fileURLWithPath: path)) else { return }
        let d = NivelXMLDelegate()
        parser.delegate = d
        parser.parse()
        withExtendedLifetime(d) {}

        for (i, battle) in d.batallas.enumerated() {
            if i < battles.count {
                let b = Batalla()
                b.objetivos = battle.objetivos.reversed()  // reversal puts first-in at last (pop = LIFO)
                b.objectiveCount = battle.objetivos.count
                battles[i] = b
                battleCount += 1
            }
        }
    }

    // MARK: - Methods

    /// Returns the next objective to complete, or nil if the level has been won.
    func nextObjective() -> Objective? {
        currentObjectiveIndex += 1
        completedObjectiveCount += 1

        guard currentBattleIndex < battles.count,
              let battle = battles[currentBattleIndex] else { return nil }

        if battle.objetivos.isEmpty {
            currentBattleIndex += 1
            currentObjectiveIndex = 0
            Log.shared.debug("Paso a la siguiente battle.")
            if currentBattleIndex >= battleCount {
                Log.shared.debug("No hay mas objetivos — gane!!")
                return nil
            }
        }

        guard currentBattleIndex < battles.count,
              let b2 = battles[currentBattleIndex],
              !b2.objetivos.isEmpty else { return nil }

        return b2.objetivos.removeLast()
    }
}

// MARK: - XML parser

private class NivelXMLDelegate: NSObject, XMLParserDelegate {

    struct BatallaData { var objetivos: [Objective] = [] }
    var batallas: [BatallaData] = []

    private var inBattle = false
    private var inObjective = false
    private var currentObj: Objective?
    private var currentCommands: [Command] = []

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
            currentObj = nil
            inObjective = false
        } else if name == "batalla" {
            inBattle = false
        }
    }
}
