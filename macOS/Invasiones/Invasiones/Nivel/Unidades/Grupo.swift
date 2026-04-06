//
//  Grupo.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Grupo.cs — collection of units sharing a movement strategy.
//

import Foundation

class Grupo {

    // MARK: - Constants
    static let SEPARACION_ENTRE_UNIDADES = 2
    static let MAXIMA_DISTANCIA = 99999
    private static var s_random: Bool = true  // initialized once

    enum ESTADO {
        case ESPERANDO_ORDEN, AGRUPANDO, MOVIENDO, SANANDO, ATANCANDO, ELIMINADO, PERSIGUIENDO_ENEMIGO
    }

    // MARK: - Statics
    static var mapa: Mapa?

    // MARK: - Attributes
    var m_inteligencia:         IA?
    private var m_proximoEstado:     ESTADO = .ESPERANDO_ORDEN
    private var m_ordenObjetivo:     Orden?
    private var m_tileObjetivo:      (x: Int, y: Int) = (0, 0)
    private var m_ordenRecibida:     Orden?
    private var m_cumplioOrden:      Bool = false
    private var m_estado:            ESTADO = .ESPERANDO_ORDEN
    private var m_unidades:          [Unidad] = []
    private var m_velocidad:         Int = 100
    private var m_esSeleccionada:    Bool = false
    private var m_comandante:        Unidad?
    private var m_promedioSalud:     Int = 0
    private var m_promedioPuntosDeResistencia: Int = 0
    private let m_idGrupo:           Int

    // MARK: - Properties
    var salud:              Int { m_promedioSalud }
    var puntosDeResistencia:Int { m_promedioPuntosDeResistencia }
    var estadoActual:       ESTADO { m_estado }
    var unidades:           [Unidad] {
        get { m_unidades }
        set { m_unidades = newValue }
    }
    var cantidadDeSoldados: Int { m_unidades.count }
    var maximaVelocidad:    Int {
        get { m_velocidad }
        set { m_velocidad = newValue }
    }
    var id: Int { m_idGrupo }

    var esSeleccionado: Bool {
        get { m_esSeleccionada }
        set {
            m_unidades.forEach { $0.esSeleccionada = newValue }
            m_esSeleccionada = newValue
        }
    }

    // MARK: - Initializer
    init(_ unidades: [Unidad]) {
        m_idGrupo  = Int.random(in: 0...99999)
        m_unidades = unidades
        m_velocidad = 100
        m_promedioPuntosDeResistencia = 0

        for unidad in unidades {
            unidad.adherirmeAGrupo(self)
            if unidad.velocidad.x < m_velocidad {
                m_velocidad = unidad.velocidad.x
            }
            m_promedioPuntosDeResistencia += unidad.puntosDeResistencia
        }
        if !m_unidades.isEmpty {
            m_promedioPuntosDeResistencia /= m_unidades.count
        }
    }

    // MARK: - Update

    func actualizar() {
        switch m_estado {
        case .ESPERANDO_ORDEN:   actualizarEstadoEsperandoOrden()
        case .MOVIENDO:          actualizarEstadoMoviendo()
        case .AGRUPANDO:         actualizarEstadoAgrupando()
        case .PERSIGUIENDO_ENEMIGO: break
        case .ATANCANDO:         break
        case .SANANDO:           actualizarEstadoSanando()
        case .ELIMINADO:         return
        }

        chequearSaludCumplioOrden()
        eliminarUnidadesMuertas()

        if m_unidades.count <= 1 {
            setearEstado(.ELIMINADO)
        }

        if let cmd = m_comandante, cmd.estaMuerto() {
            setearComandanteAuxiliar()
        }
    }

    // MARK: - Public orders

    func mover(_ x: Int, _ y: Int) {
        m_ordenRecibida = Orden(.MOVER, x, y)
        setearEstado(.AGRUPANDO)
        m_tileObjetivo  = (x, y)

        if m_comandante == nil { setearComandante() }
        m_proximoEstado = .ESPERANDO_ORDEN

        moverUnidadesAPosicionesDeseadas()
    }

    func atacar(_ enemigo: Unidad) {
        m_unidades.forEach { $0.atacar(enemigo) }
    }

    func sanar(_ x: Int, _ y: Int) {
        m_ordenRecibida = Orden(.SANAR, x, y)
        if m_comandante == nil { setearComandanteAuxiliar() }

        guard let mapa = Grupo.mapa, let cmd = m_comandante else { return }
        let p = mapa.obtenerPosicionEnLineaDeVision(
            x, cmd.posicionEnTileFisico.x,
            y, cmd.posicionEnTileFisico.y)
        if p.x == -1 {
            Log.Instancia.debug("Grupo: No se puede mandar a sanar.")
            return
        }
        setearSanar(p.x, p.y)
    }

    func setearInteligencia(_ intel: IA) {
        m_inteligencia = intel
        setearEstado(.ESPERANDO_ORDEN)
    }

    func eliminarGrupo() {
        m_unidades.forEach { $0.salirDelGrupo() }
    }

    func eliminarUnidad(_ unidad: Unidad) {
        m_unidades.removeAll { $0 === unidad }
        if unidad === m_comandante {
            m_comandante = nil
            unidad.desmarcarComandante()
            setearComandanteAuxiliar()
        }
        if m_unidades.count <= 1 { setearEstado(.ELIMINADO) }
    }

    func obtenerUltimaUnidad() -> Unidad? {
        m_unidades.count == 1 ? m_unidades[0] : nil
    }

    // MARK: - Private

    private func setearEstado(_ estado: ESTADO) {
        m_estado = estado
        if estado == .ESPERANDO_ORDEN {
            m_cumplioOrden  = false
            m_ordenRecibida = nil
        }
    }

    private func setearComandante() {
        guard !m_unidades.isEmpty else { return }
        m_comandante = m_unidades[0]
        m_comandante?.marcarComoComandante()
    }

    private func setearComandanteAuxiliar() {
        guard m_unidades.count >= 2 else { return }
        m_comandante = m_unidades[0]
        m_comandante?.marcarComoComandante()
    }

    private func setearSanar(_ x: Int, _ y: Int) {
        mover(x, y)
        m_ordenRecibida = Orden(.SANAR, x, y)
        m_proximoEstado = .SANANDO
    }

    private func actualizarEstadoEsperandoOrden() {
        guard let ia = m_inteligencia else { return }
        if m_ordenRecibida == nil {
            m_ordenRecibida = ia.proximaOrden()
        }
        if let ord = m_ordenRecibida, ord.id == .MOVER {
            setearOrdenObjetivo(.MOVER, ord.punto.x, ord.punto.y)
            mover(ord.punto.x, ord.punto.y)
        }
    }

    private func actualizarEstadoAgrupando() {
        let todoEnOcio = m_unidades.allSatisfy { $0.estadoActual == .OCIO }
        guard todoEnOcio else { return }

        guard let ord = m_ordenRecibida,
              ord.id == .MOVER || ord.id == .SANAR else { return }

        m_comandante?.mover(m_tileObjetivo.x, m_tileObjetivo.y)
        if m_comandante?.caminoASeguir == nil {
            setearEstado(.ESPERANDO_ORDEN)
            return
        }

        setearEstado(.MOVIENDO)

        if let camino = m_comandante?.caminoASeguir {
            for unidad in m_unidades {
                unidad.calcularCaminoADistancia(camino,
                                               unidad.offsetEnFormacion.x,
                                               unidad.offsetEnFormacion.y)
            }
        }
    }

    private func actualizarEstadoMoviendo() {
        let ordenSanar = m_ordenRecibida?.id == .SANAR
        let todosEnOcio = m_unidades.allSatisfy {
            $0.estadoActual == .OCIO || (ordenSanar && $0.estadoActual == .SANANDO)
        }

        if ordenSanar {
            for unidad in m_unidades where unidad.estadoActual == .OCIO {
                if unidad.salud != unidad.puntosDeResistencia {
                    unidad.recuperarSalud()
                }
            }
        }

        if todosEnOcio {
            setearEstado(m_proximoEstado)
        }
    }

    private func actualizarEstadoSanando() {
        let todosSanos = m_unidades.allSatisfy { $0.salud == $0.puntosDeResistencia }
        if todosSanos {
            setearEstado(.ESPERANDO_ORDEN)
        }
    }

    private func chequearSaludCumplioOrden() {
        guard let ord = m_ordenRecibida else { return }

        m_promedioSalud = 0
        for unidad in m_unidades {
            m_promedioSalud += unidad.salud
            if ord.id == .MOVER, unidad.cumplioOrdenObjetivoMover() {
                m_cumplioOrden = true
            }
        }
        if !m_unidades.isEmpty {
            m_promedioSalud /= m_unidades.count
            if m_cumplioOrden {
                setearEstado(.ESPERANDO_ORDEN)
            }
        } else {
            m_promedioSalud = 0
        }
    }

    private func eliminarUnidadesMuertas() {
        let muertos = m_unidades.filter { $0.estaMuerto() }
        guard !muertos.isEmpty else { return }

        m_unidades.removeAll { $0.estaMuerto() }
        m_promedioPuntosDeResistencia = 0
        if !m_unidades.isEmpty {
            m_promedioPuntosDeResistencia = m_unidades.reduce(0) { $0 + $1.puntosDeResistencia } / m_unidades.count
        }
    }

    private func moverUnidadesAPosicionesDeseadas() {
        guard let cmd = m_comandante else { return }
        let x = cmd.posicionEnTileFisico.x
        let y = cmd.posicionEnTileFisico.y
        guard let mapa = Grupo.mapa else { return }

        var i = 0, j = 0, inc = 2
        var dir = 1  // UP
        var puestos = 1
        var indice  = 0

        cmd.offsetEnFormacion = (0, 0)

        // C# parity: indice only advances when a unit is actually placed OR is the commander.
        // If the spiral position is non-walkable for a non-commander unit, we advance the spiral
        // but keep the same unit index so it is retried at the next walkable position.
        while puestos < m_unidades.count && indice < m_unidades.count {
            if m_unidades[indice] !== cmd {
                if mapa.esPosicionCaminable(x + i, y + j) {
                    m_unidades[indice].offsetEnFormacion = (i, j)
                    m_unidades[indice].mover(x + i, y + j)
                    m_unidades[indice].setearOrdenDeObjetivo(m_ordenObjetivo)
                    puestos += 1
                    indice += 1  // only advance when placed
                }
                // else: non-walkable, keep same indice and try next spiral position
            } else {
                cmd.parar()
                indice += 1
            }

            // spiral
            switch dir {
            case 1:  // UP
                i += 2; if i == inc { dir = 2 }
            case 2:  // RIGHT
                j += 2; if j == inc { dir = 3 }
            case 3:  // DOWN
                i -= 2; if i == -inc { dir = 0 }
            case 0:  // LEFT
                j -= 2; if j == -inc { dir = 1; inc += 2 }
            default: break
            }
        }
    }

    private func setearOrdenObjetivo(_ tipo: Orden.TIPO, _ x: Int, _ y: Int) {
        m_ordenObjetivo = Orden(tipo, x, y)
    }
}
