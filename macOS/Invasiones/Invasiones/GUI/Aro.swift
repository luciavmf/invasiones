//
//  Aro.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Aro.cs — animated ring indicating the current objective on the map.
//

import Foundation

class Aro: Objeto {

    // MARK: - Declarations
    private let m_animacion: Animaciones

    // MARK: - Initializer
    init(_ anim: Animaciones, _ i: Int, _ j: Int) {
        m_animacion = anim
        super.init()

        m_posEnTileFisico = (i, j)
        let p = transformarIJEnXY(i, j)
        m_posEnMundoPlano = p

        m_animacion.cargar()
        actualizarPosicionXY()

        m_posEnMundoPlano.x -= m_animacion.offsets.x
        m_posEnMundoPlano.y -= m_animacion.offsets.y

        m_animacion.reproducir()
        m_animacion.loop = true
    }

    // MARK: - Override

    @discardableResult
    override func actualizar() -> Bool {
        super.actualizar()
        m_animacion.actualizar()
        return false
    }

    override func dibujar(_ g: Video) {
        guard let mapa = Objeto.mapa else { return }
        m_animacion.dibujar(g, m_x + mapa.tileAncho / 2, m_y + mapa.tileAlto / 2, 0)
    }

    // MARK: - Own methods

    func setearPosicion(_ i: Int, _ j: Int) {
        m_posEnTileFisico = (i, j)
        let p = transformarIJEnXY(i, j)
        m_posEnMundoPlano = p
        m_posEnMundoPlano.x -= m_animacion.offsets.x
        m_posEnMundoPlano.y -= m_animacion.offsets.y
        actualizarPosicionXY()
    }
}
