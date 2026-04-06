// Nivel/Jugadores/BandoArgentino.swift
// Puerto de BandoArgentino.cs — bando controlado por el jugador.

import Foundation
internal import CoreGraphics

class BandoArgentino: Jugador {

    // MARK: - Atributos
    private var m_unidadBajoMouse:     Unidad?
    private var m_cuenta:              Int = 0
    private var m_objetoFlecha:        Objeto?
    private var m_flechaOrientacion:   Animaciones?
    private var m_posOrdenApuntada:    (x: Int, y: Int) = (0, 0)
    private var m_indiceUnidadAEncontrar: Int = 0

    private let CUENTA_MAX_FLECHA = 100

    // MARK: - Constructor
    override init(mapa: Mapa, camara: Camara, objetosAPintar: inout [[Objeto?]], hud: Hud) {
        super.init(mapa: mapa, camara: camara, objetosAPintar: &objetosAPintar, hud: hud)
        m_bando = .ARGENTINO
        Grupo.mapa = mapa

        let anims = AdministradorDeRecursos.Instancia.animaciones
        if Res.ANIM_AROS < anims.count, let animAros = anims[Res.ANIM_AROS] {
            m_aro = AnimObjeto(Animaciones(copia: animAros), 0, 0)
        }

        if Res.ANIM_FLECHA_GUIA < anims.count, let animFlecha = anims[Res.ANIM_FLECHA_GUIA] {
            m_flechaOrientacion = Animaciones(copia: animFlecha)
            m_flechaOrientacion?.cargar()
        }
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
        guard let tilesetUnidades = m_mapa.tilesets.compactMap({ $0 }).first(where: {
            $0.id == Int16(Res.TLS_UNIDADES)
        }) else { return true }

        m_unidades = []

        for i in 0..<m_mapa.ancho {
            for j in 0..<m_mapa.alto {
                let tileId = Int(m_mapa.capaUnidades[i][j])
                guard tileId != 0 else { continue }

                let localId = tileId - Int(tilesetUnidades.primerGid)
                guard localId >= 0, localId < tilesetUnidades.tiles.count,
                      let tile = tilesetUnidades.tiles[localId],
                      tile.id == Int16(Res.TILE_UNIDADES_ID_PATRICIO) else { continue }

                let lista = posicionarUnidades(Res.UNIDAD_PATRICIO, tile.cantidad, i << 1, j << 1)

                if lista.count > 1 {
                    if m_grupos == nil { m_grupos = [] }
                    m_grupos!.append(Grupo(lista))
                }
            }
        }
        return true
    }

    // MARK: - Flecha de orientación (para dibujar en Episodio)

    func dibujarFlechaOrientacion(_ g: Video) {
        m_aro?.dibujar(g)
        m_flechaOrientacion?.dibujar(g, m_posOrdenApuntada.x, m_posOrdenApuntada.y, 0)
    }

    // MARK: - Coordenadas de pintado para el Episodio

    func obtenerCoordenadasDePintado() -> (x: Int, y: Int, w: Int, h: Int) {
        // Devuelve el rectángulo del mapa físico donde dibujar objetos
        guard let cam = Objeto.camara else { return (0, 0, m_mapa.altoMapaFisico, m_mapa.anchoMapaFisico) }
        let p = calcularPrimerTileAPintar(cam.X, cam.Y)
        return (p.x, p.y, p.x + m_mapa.altoMapaFisico / 2, p.y + m_mapa.anchoMapaFisico / 2)
    }

    func seleccionarUnidadSiguiente() {
        guard !m_unidades.isEmpty else { return }
        m_indiceUnidadAEncontrar = (m_indiceUnidadAEncontrar + 1) % m_unidades.count
        m_unidadSeleccionada?.esSeleccionada = false
        m_unidadSeleccionada = m_unidades[m_indiceUnidadAEncontrar]
        m_unidadSeleccionada?.esSeleccionada = true
        m_hud.unidadSeleccionada = m_unidadSeleccionada
    }

    // MARK: - Privados

    private func actualizarEstadoJuego() {
        actualizarFlechaOrientacion()

        m_objetoATomar?.actualizar()
        m_aro?.actualizar()

        m_unidadBajoMouse = obtenerUnidadBajoMouse()
        m_unidadesSeleccionadas = []

        actualizarUnidades()
        crearGrupos()
        chequearOrdenesAUnidades()
        actualizarCursor()

        m_fueguitos?.forEach { $0.actualizar() }
        actualizarGrupos()
        actualizarObjetivos()
        eliminarUnidadesMuertas()
    }

    private func actualizarFlechaOrientacion() {
        guard m_orden != nil, m_flechaOrientacion != nil else { return }
        m_flechaOrientacion?.actualizar()
        m_cuenta += 1
        if m_cuenta > CUENTA_MAX_FLECHA {
            m_cuenta = 0
        }
    }

    private func obtenerUnidadBajoMouse() -> Unidad? {
        let mx = Int(Mouse.Instancia.X)
        let my = Int(Mouse.Instancia.Y)

        for unidad in m_unidades {
            let hw = (unidad.m_frameAncho > 0 ? unidad.m_frameAncho : 20) / 2
            let hh = (unidad.m_frameAlto  > 0 ? unidad.m_frameAlto  : 30)
            let ux = unidad.m_x
            let uy = unidad.m_y
            if mx >= ux - hw && mx <= ux + hw && my >= uy - hh && my <= uy {
                return unidad
            }
        }
        return nil
    }

    private func crearGrupos() {
        guard m_unidadesSeleccionadas.count > 1 else { return }
        // Grupos ya existen desde la carga; no recree cada frame.
    }

    private func chequearOrdenesAUnidades() {
        // Botón izquierdo: seleccionar por drag o click
        if Mouse.Instancia.arrastrando() {
            let rect = Mouse.Instancia.RectanguloArrastrado
            for unidad in m_unidades {
                _ = unidad.seleccionarSiEstaEnRectangulo(
                    Int(rect.minX), Int(rect.minY), Int(rect.width), Int(rect.height))
            }
        }

        // Botón derecho: mover unidades seleccionadas
        if Mouse.Instancia.BotonesApretados.contains(Mouse.BOTON_DER) {
            let tile = m_mapa.tileBajoMouse

            if let uBajoMouse = m_unidadBajoMouse, uBajoMouse.bando == .ENEMIGO {
                // Atacar
                for unidad in m_unidadesSeleccionadas { unidad.atacar(uBajoMouse) }
            } else {
                // Mover
                if let grupo = m_grupoSeleccionado {
                    grupo.mover(tile.x, tile.y)
                } else {
                    for unidad in m_unidadesSeleccionadas {
                        unidad.mover(tile.x, tile.y)
                    }
                }
                m_posOrdenApuntada = (m_mapa.tileBajoMouse.x, m_mapa.tileBajoMouse.y)
                m_cuenta = 0
            }
            Mouse.Instancia.soltarBoton(Mouse.BOTON_DER)
        }

        // Click izquierdo: deseleccionar
        if Mouse.Instancia.BotonesApretados.contains(Mouse.BOTON_IZQ) &&
           !Mouse.Instancia.arrastrando() {
            m_unidadesSeleccionadas.forEach { $0.esSeleccionada = false }
            borrarUnidadesSeleccionadas()
            Mouse.Instancia.soltarBoton(Mouse.BOTON_IZQ)
        }
    }

    private func actualizarCursor() {
        if let uBajoMouse = m_unidadBajoMouse, uBajoMouse.bando == .ENEMIGO {
            Mouse.Instancia.setearCursor(
                AdministradorDeRecursos.Instancia.obtenerImagen(Res.IMG_CURSOR_ESPADA))
        } else {
            Mouse.Instancia.setearCursor(
                AdministradorDeRecursos.Instancia.obtenerImagen(Res.IMG_CURSOR))
        }
    }

    private func actualizarGrupos() {
        m_grupos?.forEach { $0.actualizar() }
    }

    private func actualizarObjetivos() {
        if m_alguienCumplioLaOrden {
            setearProximaOrden()
        }
    }

    private func calcularPrimerTileAPintar(_ x: Int, _ y: Int) -> (x: Int, y: Int) {
        let th = m_mapa.tileAlto
        let tw = m_mapa.tileAncho
        let a = th > 0 ? -y / th : 0
        var b = tw > 0 ? x / tw : 0
        if x > 0 { b += 1 }
        return (a - b - 2, a + b - 1)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
