// Nivel/Jugadores/Jugador.swift
// Puerto de Jugador.cs — clase base abstracta para los bandos del juego.

import Foundation

class Jugador {

    // MARK: - Enums
    enum ESTADO { case INICIO, CARGANDO, JUEGO }

    // MARK: - Atributos protegidos
    var m_cumplioObjetivo:         Bool = false
    var m_bando:                   Episodio.BANDO = .ARGENTINO
    var m_alguienCumplioLaOrden:   Bool = false
    var m_aro:                     AnimObjeto?

    var m_hud:                     Hud
    var m_unidades:                [Unidad] = []
    var m_objetosAPintar:          TablaObjetos     // [altoMapaFisico][anchoMapaFisico]
    var m_mapa:                    Mapa
    var m_grupos:                  [Grupo]? = nil
    var m_estado:                  ESTADO = .INICIO
    var m_camara:                  Camara
    var m_unidadesSeleccionadas:   [Unidad] = []
    var m_unidadesMuertas:         [Unidad]? = nil
    var m_unidadesVisibles:        [Unidad]? = nil
    var m_unidadesPorColisionar:   [Unidad]? = nil
    var m_unidadSeleccionada:      Unidad?
    var m_grupoSeleccionado:       Grupo?
    var m_objetivo:                Objetivo?
    var m_orden:                   Orden?
    var m_objetoATomar:            Objeto?
    var m_fueguitos:               [AnimObjeto]? = nil

    var cantidadDeUnidades: Int { m_unidades.count }

    // MARK: - Constructor
    init(mapa: Mapa, camara: Camara, objetosAPintar: TablaObjetos, hud: Hud) {
        m_mapa          = mapa
        m_camara        = camara
        m_objetosAPintar = objetosAPintar
        m_hud           = hud
    }

    // MARK: - Métodos abstractos (deben ser sobreescritos)
    func actualizar() { fatalError("actualizar() must be overridden") }
    func cargarUnidades(_ nroNivel: Int) -> Bool { fatalError("cargarUnidades must be overridden") }

    // MARK: - CumplioObjetivo
    func cumplioObjetivo() -> Bool { m_cumplioObjetivo }

    // MARK: - Setear objetivo
    func setearObjetivo(_ objetivo: Objetivo?) {
        m_objetivo        = objetivo
        m_cumplioObjetivo = false

        if let obj = objetivo {
            m_orden = obj.proximaOrden()

            if let ord = m_orden {
                if ord.id == .TOMAR_OBJETO, let img = ord.imagen {
                    m_objetoATomar = Objeto(sup: img, i: ord.punto.x, j: ord.punto.y)
                }
                m_aro?.setearPosicion(ord.punto.x, ord.punto.y)
            }
        } else {
            m_orden = nil
        }

        m_unidades.forEach { $0.setearOrdenDeObjetivo(m_orden) }
    }

    func setearProximaOrden() {
        m_alguienCumplioLaOrden = false
        m_orden = m_objetivo?.proximaOrden()

        if m_orden == nil {
            m_cumplioObjetivo = true
        } else {
            // Procesar TRIGGERs automáticamente
            while let ord = m_orden, ord.id == .TRIGGER {
                if m_fueguitos == nil { m_fueguitos = [] }
                if let anim = ord.animacion {
                    m_fueguitos!.append(anim)
                    m_mapa.invalidarTile(ord.punto.x, ord.punto.y)

                    let anim2 = AnimObjeto(Animaciones(copia: anim.animacion),
                                          ord.animacion!.posicionEnTileFisico.x - 5,
                                          ord.animacion!.posicionEnTileFisico.y - 5)
                    m_fueguitos!.append(anim2)
                    m_mapa.invalidarTile(anim.posicionEnTileFisico.x - 5, anim.posicionEnTileFisico.y - 5)

                    let anim3 = AnimObjeto(Animaciones(copia: anim.animacion),
                                          ord.animacion!.posicionEnTileFisico.x - 5,
                                          ord.animacion!.posicionEnTileFisico.y)
                    m_fueguitos!.append(anim3)
                    m_mapa.invalidarTile(anim.posicionEnTileFisico.x - 5, anim.posicionEnTileFisico.y)
                }
                m_orden = m_objetivo?.proximaOrden()
                if m_orden == nil { m_cumplioObjetivo = true }
            }
            if let ord = m_orden {
                m_aro?.setearPosicion(ord.punto.x, ord.punto.y)
            }
        }

        m_unidades.forEach { $0.setearOrdenDeObjetivo(m_orden) }
    }

    // MARK: - Actualización de unidades (compartida)

    func actualizarUnidades() {
        m_unidadesMuertas = nil
        let chequearSeleccion = m_unidadSeleccionada == nil && m_grupoSeleccionado == nil

        for unidad in m_unidades {
            actualizarYMoverUnidadDelMapaDeObjetos(unidad)

            if chequearSeleccion, unidad.esSeleccionada {
                if m_unidadesSeleccionadas.count < 6 {
                    m_hud.unidadSeleccionada = unidad
                    m_unidadesSeleccionadas.append(unidad)
                } else {
                    unidad.esSeleccionada = false
                }
            }

            m_unidadesVisibles = obtenerUnidadesYTilesVisibles(unidad)

            if unidad.seEstaMoviendo() {
                chequearColisiones(unidad)
            }

            if unidad.estadoActual == .OCIO || unidad.estadoActual == .PATRULLANDO {
                atacarUnidadesVisibles(unidad)
            }

            if unidad.estadoActual == .MUERTO {
                if m_unidadesMuertas == nil { m_unidadesMuertas = [] }
                m_unidadesMuertas!.append(unidad)
            }

            if unidad.cumplioOrden { m_alguienCumplioLaOrden = true }
        }

        // Chequear orden MATAR
        if let ord = m_orden, ord.id == .MATAR {
            m_alguienCumplioLaOrden = true
            let iStart = ord.punto.x - ord.ancho
            let iEnd   = ord.punto.x + ord.ancho
            let jStart = ord.punto.y - ord.ancho
            let jEnd   = ord.punto.y + ord.ancho

            for i in iStart..<iEnd {
                for j in jStart..<jEnd {
                    guard i >= 0, j >= 0, i < m_objetosAPintar.tabla.count,
                          j < m_objetosAPintar.tabla[i].count else { continue }
                    if let u = m_objetosAPintar.tabla[i][j] as? Unidad, u.bando == .ENEMIGO {
                        m_alguienCumplioLaOrden = false
                    }
                }
            }
        }
    }

    func eliminarUnidadesMuertas() {
        guard let muertas = m_unidadesMuertas else { return }
        for muerta in muertas {
            let ti = muerta.posicionEnTileFisico.x
            let tj = muerta.posicionEnTileFisico.y
            if ti < m_objetosAPintar.tabla.count, tj < m_objetosAPintar.tabla[ti].count {
                m_objetosAPintar.tabla[ti][tj] = nil
            }
            m_unidades.removeAll { $0 === muerta }
        }
    }

    // MARK: - Privados

    private func actualizarYMoverUnidadDelMapaDeObjetos(_ unidad: Unidad) {
        let movio = unidad.actualizar()
        if movio {
            let antI = unidad.tileAnterior.x
            let antJ = unidad.tileAnterior.y
            if antI < m_objetosAPintar.tabla.count, antJ < m_objetosAPintar.tabla[antI].count {
                if m_objetosAPintar.tabla[antI][antJ] === unidad {
                    m_objetosAPintar.tabla[antI][antJ] = nil
                }
            }
            let ni = unidad.posicionEnTileFisico.x
            let nj = unidad.posicionEnTileFisico.y
            if ni < m_objetosAPintar.tabla.count, nj < m_objetosAPintar.tabla[ni].count {
                m_objetosAPintar.tabla[ni][nj] = unidad
            }
        }
    }

    private func chequearColisiones(_ unidad: Unidad) {
        m_unidadesPorColisionar = obtenerUnidadesPorColisionar(unidad)
        for otra in (m_unidadesPorColisionar ?? []) {
            if unidad.hayColision(otra) {
                unidad.esquivarUnidad(otra, m_unidadesVisibles)
            }
        }
    }

    func obtenerUnidadesYTilesVisibles(_ unidad: Unidad) -> [Unidad]? {
        var visibles: [Unidad]? = nil
        let iInicio = max(0, unidad.posicionEnTileFisico.x - Unidad.MAXIMA_VISIBILIDAD)
        let jInicio = max(0, unidad.posicionEnTileFisico.y - Unidad.MAXIMA_VISIBILIDAD)
        let iFin    = min(m_mapa.altoMapaFisico,  unidad.posicionEnTileFisico.x + Unidad.MAXIMA_VISIBILIDAD)
        let jFin    = min(m_mapa.anchoMapaFisico, unidad.posicionEnTileFisico.y + Unidad.MAXIMA_VISIBILIDAD)
        let esVisible = unidad.esVisibleEnPantalla()

        for i in iInicio..<iFin {
            for j in jInicio..<jFin {
                let dist = unidad.calcularDistancia(i, j)
                guard dist <= Double(unidad.visibilidad) else { continue }

                if i < m_objetosAPintar.tabla.count, j < m_objetosAPintar.tabla[i].count,
                   let otra = m_objetosAPintar.tabla[i][j] as? Unidad, otra !== unidad {
                    if visibles == nil { visibles = [] }
                    visibles!.append(otra)
                }

                if esVisible && unidad.bando == .ARGENTINO {
                    m_mapa.capaTilesVisibles[i][j] = Int16(Mapa.TILE_VISIBLE)
                }
            }
        }
        return visibles
    }

    private func obtenerUnidadesPorColisionar(_ unidad: Unidad) -> [Unidad]? {
        var cercanas: [Unidad]? = nil
        let rango = Unidad.DISTANCIA_A_CHEQUEAR_COLISION
        let iInicio = max(0, unidad.posicionEnTileFisico.x - rango)
        let jInicio = max(0, unidad.posicionEnTileFisico.y - rango)
        let iFin    = min(m_mapa.altoMapaFisico,  unidad.posicionEnTileFisico.x + rango)
        let jFin    = min(m_mapa.anchoMapaFisico, unidad.posicionEnTileFisico.y + rango)

        for i in iInicio..<iFin {
            for j in jInicio..<jFin {
                guard i < m_objetosAPintar.tabla.count, j < m_objetosAPintar.tabla[i].count,
                      let otra = m_objetosAPintar.tabla[i][j] as? Unidad, otra !== unidad else { continue }
                let dist = otra.calcularDistancia(unidad.posicionEnTileFisico.x,
                                                  unidad.posicionEnTileFisico.y)
                if dist <= Double(rango) {
                    if cercanas == nil { cercanas = [] }
                    cercanas!.append(otra)
                }
            }
        }
        return cercanas
    }

    private func atacarUnidadesVisibles(_ unidad: Unidad) {
        guard let visibles = m_unidadesVisibles else { return }
        for enemigo in visibles {
            if enemigo.bando != m_bando, !enemigo.estaMuerto() {
                unidad.atacar(enemigo)
            }
        }
    }

    func posicionarUnidades(_ tipo: Int, _ cant: Int, _ x: Int, _ y: Int) -> [Unidad] {
        guard cant > 0 else {
            Log.Instancia.error("No se puede crear un grupo de cantidad 0.")
            return []
        }

        var grupo:   [Unidad] = []
        var i = 0, j = 0, inc = 2
        var dir = 1  // ARR
        var puestos = 0

        while puestos < cant {
            if m_mapa.esPosicionCaminable(x + i, y + j) {
                if let u = ponerUnidad(tipo, x + i, y + j) {
                    grupo.append(u)
                }
                puestos += 1
            }

            switch dir {
            case 1: i += 2; if i == inc { dir = 2 }
            case 2: j += 2; if j == inc { dir = 3 }
            case 3: i -= 2; if i == -inc { dir = 0 }
            case 0: j -= 2; if j == -inc { dir = 1; inc += 2 }
            default: break
            }
        }
        return grupo
    }

    private func ponerUnidad(_ tipo: Int, _ i: Int, _ j: Int) -> Unidad? {
        guard m_mapa.esPosicionCaminable(i, j) else {
            Log.Instancia.debug("No se puede posicionar la unidad: tile no caminable.")
            return nil
        }
        let unit = Unidad(tipo)
        unit.posicionEnTileFisico = (i, j)
        unit.tileAnterior         = (i, j)
        unit.inicializarXY()
        unit.bando = m_bando

        m_unidades.append(unit)
        if i < m_objetosAPintar.tabla.count, j < m_objetosAPintar.tabla[i].count {
            m_objetosAPintar.tabla[i][j] = unit
        }
        return unit
    }

    func borrarUnidadesSeleccionadas() {
        m_grupoSeleccionado?.esSeleccionado = false
        m_unidadSeleccionada?.esSeleccionada = false
        m_hud.unidadSeleccionada = nil
        m_grupoSeleccionado   = nil
        m_unidadSeleccionada  = nil
    }
}
