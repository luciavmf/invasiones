// Nivel/Nivel.swift
// Puerto de Nivel.cs — gestión de batallas y objetivos de un nivel.

import Foundation

class Nivel {

    // MARK: - Constantes
    static let MAXIMA_CANTIDAD_BATALLAS = 5

    // MARK: - Clase privada
    private class Batalla {
        var m_objetivos:          [Objetivo] = []  // LIFO: popLast
        var cantidadDeObjetivos:  Int = 0
    }

    // MARK: - Declaraciones
    private var m_batallas:      [Batalla?]
    private var m_nroBatallaActual:       Int = 0
    private var m_cantidadDeBatallas:     Int = 0
    private var m_nroObjetivoActual:      Int = 0
    private var m_cantidadDeObjetivosCumplidos: Int = -1

    // MARK: - Propiedades
    var nroObjetivoActual:            Int { m_nroObjetivoActual }
    var nroBatallaActual:             Int { m_nroBatallaActual }
    var cantidadDeBatallas:           Int { m_cantidadDeBatallas }
    var cantidadDeObjetivosCumplidos: Int { m_cantidadDeObjetivosCumplidos }

    var cantidadDeObjetivosActuales: Int {
        guard m_nroBatallaActual < m_batallas.count,
              let b = m_batallas[m_nroBatallaActual] else { return 0 }
        return b.cantidadDeObjetivos
    }

    // MARK: - Constructor
    init() {
        m_batallas = Array(repeating: nil, count: Nivel.MAXIMA_CANTIDAD_BATALLAS)
        m_nroBatallaActual  = 0
        m_cantidadDeBatallas = 0
        m_cantidadDeObjetivosCumplidos = -1
    }

    // MARK: - Carga

    func cargar(_ nroNivel: Int) {
        let pathStr = Programa.PATH_NIVEL + "/nivel_\(nroNivel).xml"
        guard let path = Utilidades.obtenerPath(pathStr) else {
            Log.Instancia.debug("No se pueden cargar los objetivos. No se encuentra el archivo: \(pathStr)")
            return
        }
        m_nroBatallaActual   = 0
        m_nroObjetivoActual  = 0
        m_cantidadDeBatallas = 0

        guard let parser = XMLParser(contentsOf: URL(fileURLWithPath: path)) else { return }
        let d = NivelXMLDelegate()
        parser.delegate = d
        parser.parse()
        withExtendedLifetime(d) {}

        for (i, batalla) in d.batallas.enumerated() {
            if i < m_batallas.count {
                let b = Batalla()
                b.m_objetivos = batalla.objetivos.reversed()  // reversal puts first-in at last (pop = LIFO)
                b.cantidadDeObjetivos = batalla.objetivos.count
                m_batallas[i] = b
                m_cantidadDeBatallas += 1
            }
        }
    }

    // MARK: - Métodos

    /// Devuelve el próximo objetivo a cumplir, o nil si se ganó.
    func proximoObjetivo() -> Objetivo? {
        m_nroObjetivoActual += 1
        m_cantidadDeObjetivosCumplidos += 1

        guard m_nroBatallaActual < m_batallas.count,
              let batalla = m_batallas[m_nroBatallaActual] else { return nil }

        if batalla.m_objetivos.isEmpty {
            m_nroBatallaActual += 1
            m_nroObjetivoActual = 0
            Log.Instancia.debug("Paso a la siguiente batalla.")
            if m_nroBatallaActual >= m_cantidadDeBatallas {
                Log.Instancia.debug("No hay mas objetivos — gane!!")
                return nil
            }
        }

        guard m_nroBatallaActual < m_batallas.count,
              let b2 = m_batallas[m_nroBatallaActual],
              !b2.m_objetivos.isEmpty else { return nil }

        return b2.m_objetivos.removeLast()
    }
}

// MARK: - Parser XML

private class NivelXMLDelegate: NSObject, XMLParserDelegate {

    struct BatallaData { var objetivos: [Objetivo] = [] }
    var batallas: [BatallaData] = []

    private var enBatalla  = false
    private var enObjetivo = false
    private var objActual:  Objetivo?
    private var ordActual:  [Orden]  = []

    func parser(_ parser: XMLParser, didStartElement name: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes a: [String: String]) {
        switch name {
        case "batalla":
            enBatalla = true
            batallas.append(BatallaData())
        case "objetivo":
            let imgPath = a["imagen"]
            objActual = Objetivo(pathImagen: imgPath)
            ordActual = []
            enObjetivo = true
        case "tomar", "llegar", "trigger", "matar":
            guard enObjetivo else { return }
            let iVal = (Int(a["i"] ?? "0") ?? 0) << 1
            let jVal = (Int(a["j"] ?? "0") ?? 0) << 1
            let tipo: Orden.TIPO
            switch name {
            case "tomar":   tipo = .TOMAR_OBJETO
            case "llegar":  tipo = .MOVER
            case "trigger": tipo = .TRIGGER
            case "matar":   tipo = .MATAR
            default:        tipo = .INVALIDA
            }
            let ord: Orden
            if tipo == .TOMAR_OBJETO, let img = a["imagen"] {
                ord = Orden(tipo, iVal, jVal, img)
            } else if tipo == .TRIGGER, let t = a["tipo"] {
                let animIdx: Int
                switch t {
                case "fuego1": animIdx = Res.ANIM_FUEGO_1
                case "fuego2": animIdx = Res.ANIM_FUEGO_2
                default: animIdx = -1
                }
                if animIdx >= 0,
                   let anim = AdministradorDeRecursos.Instancia.animaciones[animIdx] {
                    let animObj = AnimObjeto(Animaciones(copia: anim), iVal, jVal)
                    ord = Orden(tipo, iVal, jVal, animObj)
                } else {
                    ord = Orden(tipo, iVal, jVal)
                }
            } else if tipo == .MATAR, let anchoStr = a["ancho"] {
                ord = Orden(tipo, iVal, jVal, (Int(anchoStr) ?? 0) << 1)
            } else {
                ord = Orden(tipo, iVal, jVal)
            }
            ordActual.append(ord)
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement name: String,
                namespaceURI: String?, qualifiedName: String?) {
        if name == "objetivo", let obj = objActual {
            obj.ordenes = ordActual.reversed()
            batallas[batallas.count - 1].objetivos.append(obj)
            objActual  = nil
            enObjetivo = false
        } else if name == "batalla" {
            enBatalla = false
        }
    }
}
