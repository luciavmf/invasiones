// Nivel/IA.swift
// Puerto de IA.cs — inteligencia artificial de los grupos enemigos.

import Foundation

class IA {

    // MARK: - Clase privada
    private class Batalla {
        var m_ordenes: [Orden] = []  // LIFO via popLast
    }

    // MARK: - Declaraciones
    private var m_batallas:           [Batalla]
    private var m_cantidadDeBatallas: Int = 0
    private var m_nroBatallaActual:   Int = 0

    // MARK: - Constructor
    init() {
        m_batallas = Array(repeating: Batalla(), count: Nivel.MAXIMA_CANTIDAD_BATALLAS)
    }

    // MARK: - Carga

    func cargar(_ x: Int, _ y: Int, _ nroNivel: Int) {
        let pathStr = Programa.PATH_NIVEL + "/orden_nv\(nroNivel)_\(x)_\(y).xml"
        guard let path = Utilidades.obtenerPath(pathStr) else {
            Log.Instancia.debug("IA: No se encuentra el archivo: \(pathStr)")
            return
        }
        m_cantidadDeBatallas = 0

        guard let parser = XMLParser(contentsOf: URL(fileURLWithPath: path)) else { return }
        let d = IAXMLDelegate()
        parser.delegate = d
        parser.parse()
        withExtendedLifetime(d) {}

        for (i, ordenes) in d.batallas.enumerated() {
            if i < m_batallas.count {
                m_batallas[i].m_ordenes = ordenes.reversed()
                m_cantidadDeBatallas += 1
            }
        }
        m_nroBatallaActual = 0
    }

    // MARK: - Métodos

    func proximaOrden() -> Orden? {
        guard m_nroBatallaActual < m_cantidadDeBatallas else {
            Log.Instancia.debug("IA: No hay mas batallas.")
            return nil
        }

        if m_batallas[m_nroBatallaActual].m_ordenes.isEmpty {
            Log.Instancia.debug("IA: Paso a la siguiente batalla.")
            m_nroBatallaActual += 1
            if m_nroBatallaActual >= m_cantidadDeBatallas {
                Log.Instancia.debug("IA: No hay mas batallas.")
                return nil
            }
        }

        return m_batallas[m_nroBatallaActual].m_ordenes.popLast()
    }
}

// MARK: - Parser XML

private class IAXMLDelegate: NSObject, XMLParserDelegate {
    var batallas:   [[Orden]] = []
    private var current: [Orden] = []
    private var enBatalla = false

    func parser(_ parser: XMLParser, didStartElement name: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes a: [String: String]) {
        if name == "batalla" {
            enBatalla = true
            current = []
        } else if enBatalla {
            let iVal = (Int(a["i"] ?? "0") ?? 0) << 1
            let jVal = (Int(a["j"] ?? "0") ?? 0) << 1
            let tipo: Orden.TIPO
            switch name {
            case "llegar":    tipo = .MOVER
            case "patrullar": tipo = .PATRULLAR
            default:          tipo = .INVALIDA
            }
            if tipo != .INVALIDA {
                current.append(Orden(tipo, iVal, jVal))
            }
        }
    }

    func parser(_ parser: XMLParser, didEndElement name: String,
                namespaceURI: String?, qualifiedName: String?) {
        if name == "batalla" {
            batallas.append(current.reversed())
            current   = []
            enBatalla = false
        }
    }
}
