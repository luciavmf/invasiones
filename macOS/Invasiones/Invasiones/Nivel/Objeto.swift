//
//  Objeto.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Objeto.cs — base class for all map objects (obstacles, units, animations).
//

import Foundation

class Objeto {

    // MARK: - Shared statics (equivalent to static fields in C#)
    static var camara: Camara?
    static var mapa:   Mapa?

    // MARK: - Attributes
    var m_imagen:            Superficie?
    var m_posEnMundoPlano:   (x: Int, y: Int) = (0, 0)
    var m_posEnTileFisico:   (x: Int, y: Int) = (0, 0)
    var m_posEnTileAnterior: (x: Int, y: Int) = (0, 0)
    var m_frameAncho:        Int = 0
    var m_frameAlto:         Int = 0
    var m_x:                 Int = 0
    var m_y:                 Int = 0

    // MARK: - Public properties
    var posicionEnTileFisico: (x: Int, y: Int) {
        get { m_posEnTileFisico }
        set { m_posEnTileFisico = newValue }
    }

    var tileAnterior: (x: Int, y: Int) {
        get { m_posEnTileAnterior }
        set { m_posEnTileAnterior = newValue }
    }

    var posEnMundoPlano: (x: Int, y: Int) { m_posEnMundoPlano }

    // MARK: - Initializeres

    init() {}

    init(sup: Superficie?, i: Int, j: Int) {
        m_imagen = sup
        if let img = sup {
            m_frameAlto  = img.alto
            m_frameAncho = img.ancho
        }
        m_posEnTileFisico = (i, j)
        let p = transformarIJEnXY(i, j)
        m_posEnMundoPlano = p
    }

    // MARK: - Methods

    @discardableResult
    func actualizar() -> Bool {
        actualizarPosicionXY()
        return false
    }

    func actualizarPosicionXY() {
        guard let cam = Objeto.camara else { return }
        m_x = cam.inicioX + m_posEnMundoPlano.x + cam.X
        m_y = cam.inicioY + m_posEnMundoPlano.y + cam.Y
    }

    func dibujar(_ g: Video) {
        guard let img = m_imagen, let mapa = Objeto.mapa else { return }
        g.dibujar(img,
                  m_x - m_frameAncho / 2 + mapa.tileAncho / 2,
                  m_y - m_frameAlto  + mapa.tileAlto  / 4,
                  0)
    }

    /// Transforms tile (i, j) into (x, y) position in the flat world.
    func transformarIJEnXY(_ i: Int, _ j: Int) -> (x: Int, y: Int) {
        guard let mapa = Objeto.mapa else { return (0, 0) }
        let x = ((i - j) * mapa.tileAncho / 2) >> 1
        let y = ((i + j) * mapa.tileAlto  / 2) >> 1
        return (x, y)
    }

    func setearPosicionEnTile(_ i: Int, _ j: Int) {
        m_posEnTileFisico = (i, j)
        let p = transformarIJEnXY(i, j)
        m_posEnMundoPlano = p
        actualizarPosicionXY()
    }

    // Initializes m_x, m_y from the current tile position (called when creating the unit).
    func inicializarXY() {
        let p = transformarIJEnXY(m_posEnTileFisico.x, m_posEnTileFisico.y)
        m_posEnMundoPlano = p
        actualizarPosicionXY()
    }
}
