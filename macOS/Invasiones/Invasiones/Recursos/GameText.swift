//
//  GameText.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Texto.cs — loads and caches localised strings from strings.xml.
//  Uses XMLParser (SAX) instead of .NET's XmlTextReader.
//

import Foundation

class GameText: NSObject, XMLParserDelegate {

    // MARK: - Static storage
    private static var s_strings: [String]?

    /// Loads the strings from strings.xml in the bundle.
    @discardableResult
    static func loadStrings() -> Bool {
        s_strings = Array(repeating: "", count: Res.STR_COUNT)

        guard let path = Utils.getPath(Program.STRINGS_XML_FILE) else {
            Log.shared.error("No se encuentra el archivo \(Program.STRINGS_XML_FILE).")
            return false
        }

        let parser = GameText()
        let xmlParser = XMLParser(contentsOf: URL(fileURLWithPath: path))
        xmlParser?.delegate = parser
        let ok = xmlParser?.parse() ?? false

        if !ok {
            Log.shared.error("Error al leer el archivo \(Program.STRINGS_XML_FILE).")
            return false
        }

        s_strings = parser.m_parsedStrings
        return true
    }

    /// Returns the strings array (lazy-loads if not yet loaded).
    static var Strings: [String] {
        if s_strings == nil {
            GameText.loadStrings()
        }
        return s_strings ?? []
    }

    // MARK: - XMLParserDelegate (temporary instance used only during parsing)
    private var m_parsedStrings: [String] = Array(repeating: "", count: Res.STR_COUNT)
    private var m_index = 0
    private var m_currentText = ""
    private var m_inElement = false

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
        // Skip the root element (<strings>)
        if elementName.lowercased() != "strings" {
            m_currentText = ""
            m_inElement = true
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if m_inElement {
            m_currentText += string
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        if m_inElement && m_index < Res.STR_COUNT {
            let trimmed = m_currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            // strings.xml uses the literal sequence "\n"; convert it to a real newline.
            m_parsedStrings[m_index] = trimmed.replacingOccurrences(of: "\\n", with: "\n")
            m_index += 1
            m_inElement = false
        }
    }
}
