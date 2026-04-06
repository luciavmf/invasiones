//
//  Texto.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Texto.cs — loads and caches localised strings from strings.xml.
//  Uses XMLParser (SAX) instead of .NET's XmlTextReader.
//

import Foundation

class Texto: NSObject, XMLParserDelegate {

    // MARK: - Static storage
    private static var s_strings: [String]?

    /// Loads the strings from strings.xml in the bundle.
    @discardableResult
    static func cargar() -> Bool {
        s_strings = Array(repeating: "", count: Res.STR_COUNT)

        guard let path = Utilidades.obtenerPath(Programa.ARCHIVO_XML_TEXTOS) else {
            Log.Instancia.error("No se encuentra el archivo \(Programa.ARCHIVO_XML_TEXTOS).")
            return false
        }

        let parser = Texto()
        let xmlParser = XMLParser(contentsOf: URL(fileURLWithPath: path))
        xmlParser?.delegate = parser
        let ok = xmlParser?.parse() ?? false

        if !ok {
            Log.Instancia.error("Error al leer el archivo \(Programa.ARCHIVO_XML_TEXTOS).")
            return false
        }

        s_strings = parser.m_stringsLeidos
        return true
    }

    /// Returns the strings array (lazy-loads if not yet loaded).
    static var Strings: [String] {
        if s_strings == nil {
            cargar()
        }
        return s_strings ?? []
    }

    // MARK: - XMLParserDelegate (temporary instance used only during parsing)
    private var m_stringsLeidos: [String] = Array(repeating: "", count: Res.STR_COUNT)
    private var m_indice = 0
    private var m_textoActual = ""
    private var m_enElemento = false

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
        // Skip the root element (<strings>)
        if elementName.lowercased() != "strings" {
            m_textoActual = ""
            m_enElemento = true
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if m_enElemento {
            m_textoActual += string
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        if m_enElemento && m_indice < Res.STR_COUNT {
            let trimmed = m_textoActual.trimmingCharacters(in: .whitespacesAndNewlines)
            // strings.xml uses the literal sequence "\n"; convert it to a real newline.
            m_stringsLeidos[m_indice] = trimmed.replacingOccurrences(of: "\\n", with: "\n")
            m_indice += 1
            m_enElemento = false
        }
    }
}
