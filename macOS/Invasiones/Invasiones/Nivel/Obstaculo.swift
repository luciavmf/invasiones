// Nivel/Obstaculo.swift
// Puerto de Obstaculo.cs — representación de un obstáculo estático en el mapa (árbol, edificio, roca).

import Foundation

class Obstaculo: Objeto {

    // MARK: - Declaraciones
    private var m_indice:    Int  = 0
    private var m_esEdificio: Bool = false

    // MARK: - Constructor
    init(indice: Int, i: Int, j: Int, tileset: Tileset) {
        super.init()
        m_indice = indice

        m_frameAlto  = Int(tileset.altoDelTile)
        m_frameAncho = Int(tileset.anchoDelTile)

        m_posEnTileFisico = (i, j)
        m_imagen          = tileset.imagen

        let p = transformarIJEnXY(i, j)
        m_posEnMundoPlano = p

        if tileset.id == Int16(Res.TLS_EDIFICIOS) ||
           tileset.id == Int16(Res.TLS_ENFERMERIA) ||
           tileset.id == Int16(Res.TLS_FUERTE) {
            m_esEdificio = true
        }

        if tileset.id == Int16(Res.TLS_DEBUG) {
            m_imagen = nil
        }

        actualizarPosicionXY()
    }

    // MARK: - Override

    @discardableResult
    override func actualizar() -> Bool {
        actualizarPosicionXY()
        return false
    }

    override func dibujar(_ g: Video) {
        guard let img = m_imagen, let mapa = Objeto.mapa else { return }
        img.setearClip(m_indice * m_frameAncho, 0, m_frameAncho, m_frameAlto)
        if m_esEdificio {
            g.dibujar(img, m_x, m_y - m_frameAlto + mapa.tileAlto / 2, 0)
        } else {
            g.dibujar(img,
                      m_x - m_frameAncho / 2 + mapa.tileAncho / 2,
                      m_y - m_frameAlto  + mapa.tileAlto / 2,
                      0)
        }
    }
}
