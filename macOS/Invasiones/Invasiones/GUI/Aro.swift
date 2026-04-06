// GUI/Aro.swift
// Puerto de Aro.cs — aro animado que indica el objetivo actual en el mapa.

import Foundation

class Aro: Objeto {

    // MARK: - Declaraciones
    private let m_animacion: Animaciones

    // MARK: - Constructor
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

    // MARK: - Métodos propios

    func setearPosicion(_ i: Int, _ j: Int) {
        m_posEnTileFisico = (i, j)
        let p = transformarIJEnXY(i, j)
        m_posEnMundoPlano = p
        m_posEnMundoPlano.x -= m_animacion.offsets.x
        m_posEnMundoPlano.y -= m_animacion.offsets.y
        actualizarPosicionXY()
    }
}
