// Recursos/Texto.swift
// Puerto de Texto.cs — carga y caché de strings localizados desde strings.xml.
// Usa XMLParser (SAX) en lugar de XmlTextReader de .NET.

import Foundation

class Texto: NSObject, XMLParserDelegate {

    // MARK: - Static storage
    private static var s_strings: [String]?

    /// Carga los strings desde strings.xml en el bundle.
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

    /// Devuelve el array de strings (carga lazy si aún no fue cargado).
    static var Strings: [String] {
        if s_strings == nil {
            cargar()
        }
        return s_strings ?? []
    }

    // MARK: - XMLParserDelegate (instancia temporal usada solo durante el parseo)
    private var m_stringsLeidos: [String] = Array(repeating: "", count: Res.STR_COUNT)
    private var m_indice = 0
    private var m_textoActual = ""
    private var m_enElemento = false

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
        // Saltar el elemento raíz (<strings>)
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
            // strings.xml usa la secuencia literal "\n"; convertirla a salto de línea real.
            m_stringsLeidos[m_indice] = trimmed.replacingOccurrences(of: "\\n", with: "\n")
            m_indice += 1
            m_enElemento = false
        }
    }
}
