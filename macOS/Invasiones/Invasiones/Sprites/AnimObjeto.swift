//
//  AnimObjeto.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of AnimObjeto.cs — animated object positioned on a map tile (fire, etc.).
//

import Foundation

class AnimObjeto: Objeto {

    // MARK: - Declarations
    private(set) var animacion: Animaciones

    // MARK: - Initializer
    init(_ anim: Animaciones, _ i: Int, _ j: Int) {
        animacion = anim
        super.init()

        m_posEnTileFisico = (i, j)
        let p = transformarIJEnXY(i, j)
        m_posEnMundoPlano = p

        animacion.cargar()
        actualizarPosicionXY()

        m_posEnMundoPlano.x -= animacion.offsets.x
        m_posEnMundoPlano.y -= animacion.offsets.y

        animacion.reproducir()
        animacion.loop = true
    }

    // MARK: - Override

    @discardableResult
    override func actualizar() -> Bool {
        super.actualizar()
        animacion.actualizar()
        return false
    }

    override func dibujar(_ g: Video) {
        guard let mapa = Objeto.mapa else { return }
        if m_posEnMundoPlano.x == -1 || m_posEnMundoPlano.y == -1 { return }
        animacion.dibujar(g, m_x + mapa.tileAncho / 2, m_y + mapa.tileAlto / 2, 0)
    }

    // MARK: - Own methods

    func setearAnimacion(_ anim: Int) {
        animacion.setearAnimacion(anim)
    }

    func setearPosicion(_ i: Int, _ j: Int) {
        m_posEnTileFisico = (i, j)
        let p = transformarIJEnXY(i, j)
        m_posEnMundoPlano = p
        m_posEnMundoPlano.x -= animacion.offsets.x
        m_posEnMundoPlano.y -= animacion.offsets.y
        actualizarPosicionXY()
    }
}
