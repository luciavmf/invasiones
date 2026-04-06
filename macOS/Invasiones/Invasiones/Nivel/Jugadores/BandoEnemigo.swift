// Nivel/Jugadores/BandoEnemigo.swift
// Puerto de BandoEnemigo.cs — bando controlado por la IA.

import Foundation

class BandoEnemigo: Jugador {

    // MARK: - Constructor
    override init(mapa: Mapa, camara: Camara, objetosAPintar: inout [[Objeto?]], hud: Hud) {
        super.init(mapa: mapa, camara: camara, objetosAPintar: &objetosAPintar, hud: hud)
        m_bando = .ENEMIGO
    }

    // MARK: - Override

    override func actualizar() {
        switch m_estado {
        case .INICIO:   m_estado = .CARGANDO
        case .CARGANDO: m_estado = .JUEGO
        case .JUEGO:    actualizarEstadoJuego()
        }
    }

    override func cargarUnidades(_ nroNivel: Int) -> Bool {
        guard let tilesetUnidades = m_mapa.tilesets.first(where: {
            $0?.id == Int16(Res.TLS_UNIDADES)
        }) as? Tileset? else { return true }
        guard let ts = tilesetUnidades else { return true }

        m_unidades = []

        for i in 0..<m_mapa.ancho {
            for j in 0..<m_mapa.alto {
                let tileId = Int(m_mapa.capaUnidades[i][j])
                guard tileId != 0 else { continue }

                let localId = tileId - Int(ts.primerGid)
                guard localId >= 0, localId < ts.tiles.count,
                      let tile = ts.tiles[localId],
                      tile.id == Int16(Res.TILE_UNIDADES_ID_INGLES) else { continue }

                let lista = posicionarUnidades(Res.UNIDAD_INGLES, tile.cantidad, i << 1, j << 1)

                if lista.count > 1 {
                    if m_grupos == nil { m_grupos = [] }
                    let nuevoGrupo = Grupo(lista)
                    let ia = IA()
                    ia.cargar(i, j, nroNivel)
                    nuevoGrupo.setearInteligencia(ia)
                    m_grupos!.append(nuevoGrupo)
                } else {
                    lista.forEach { $0.patrullar() }
                }
            }
        }
        return true
    }

    // MARK: - Privados

    private func actualizarEstadoJuego() {
        m_unidadesSeleccionadas = []
        actualizarUnidades()
        eliminarUnidadesMuertas()
        actualizarOrdenes()
        actualizarGrupos()
    }

    private func actualizarGrupos() {
        m_grupos?.forEach { $0.actualizar() }
    }

    private func actualizarOrdenes() {
        guard !m_unidadesSeleccionadas.isEmpty else { return }
        if Mouse.Instancia.BotonesApretados.contains(Mouse.BOTON_IZQ) {
            m_unidadesSeleccionadas.forEach { $0.esSeleccionada = false }
            borrarUnidadesSeleccionadas()
        }
    }
}
