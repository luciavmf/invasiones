// Map/Camara.swift
// Puerto de Camara.cs — representa la porción visible del mapa (viewport).

import Foundation

class Camara {

    // MARK: - Declaraciones
    var X: Int
    var Y: Int

    private var m_inicioX: Int = 0
    private var m_inicioY: Int = 0
    private var m_ancho:   Int = Programa.ANCHO_DE_LA_PANTALLA
    private var m_alto:    Int
    private var m_borde:   Int = 20
    private var m_velocidad: Int = 20

    // MARK: - Properties
    var inicioX:   Int { m_inicioX }
    var inicioY:   Int { m_inicioY }
    var ancho:     Int { m_ancho }
    var alto:      Int { m_alto }
    var borde:     Int { m_borde }
    var velocidad: Int { m_velocidad }

    // MARK: - Constructor
    init(x: Int, y: Int, alto: Int) {
        X = x
        Y = y
        m_alto = alto
    }

    // MARK: - Métodos

    func setearCoordenadasDeLaPantalla(_ x: Int, _ y: Int, _ w: Int, _ h: Int) {
        m_inicioX = max(0, x)
        m_inicioY = max(0, y)
        m_ancho   = (w + x <= Programa.ANCHO_DE_LA_PANTALLA) ? w : (Programa.ANCHO_DE_LA_PANTALLA - x)
        m_alto    = (h + y <= Programa.ALTO_DE_LA_PANTALLA)  ? h : (Programa.ALTO_DE_LA_PANTALLA  - y)
    }
}
