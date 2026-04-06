// Nivel/Jugadores/BandoArgentino.swift
// Puerto de BandoArgentino.cs — bando controlado por el jugador.

import Foundation
internal import CoreGraphics

class BandoArgentino: Jugador {

    // MARK: - Atributos
    private var m_unidadBajoMouse:            Unidad?
    private var m_cuenta:                     Int = 0
    private var m_objetoFlecha:               Objeto?
    private var m_flechaOrientacion:          Animaciones?
    private var m_posOrdenApuntada:           (x: Int, y: Int) = (0, 0)
    private var m_posicionFlechaOrientacion:  (x: Int, y: Int) = (0, 0)
    private var m_indiceUnidadAEncontrar:     Int = 0

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
        m_objetoFlecha = Objeto(sup: AdministradorDeRecursos.Instancia.obtenerImagen(Res.IMG_FLECHA),
                               i: 0, j: 0)
        m_cuenta = 99999

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

    // MARK: - Dibujar (llamado desde Episodio)

    func dibujarFlechaOrientacion(_ g: Video) {
        guard m_estado == .JUEGO else { return }

        // Dibujar aro de objetivo, objeto a tomar y fueguitos
        m_aro?.dibujar(g)
        m_objetoATomar?.dibujar(g)
        m_fueguitos?.forEach { $0.dibujar(g) }

        // Dibujar flecha destino estática si hay orden reciente
        if m_cuenta < CUENTA_MAX_FLECHA {
            m_objetoFlecha?.dibujar(g)
        }

        // Dibujar flecha de orientación sólo si el objetivo está fuera de pantalla
        guard m_orden != nil, m_flechaOrientacion != nil else { return }
        guard !objetivoEsVisible() else { return }
        m_flechaOrientacion?.dibujar(g, m_posicionFlechaOrientacion.x,
                                     m_posicionFlechaOrientacion.y, 0)
    }

    // MARK: - Coordenadas de pintado para el Episodio

    func obtenerCoordenadasDePintado() -> (x: Int, y: Int, w: Int, h: Int) {
        guard let cam = Objeto.camara else {
            return (0, 0, m_mapa.altoMapaFisico, m_mapa.anchoMapaFisico)
        }
        let p = calcularPrimerTileAPintar(cam.X, cam.Y)
        let tw = m_mapa.tileFisicoAncho > 0 ? m_mapa.tileFisicoAncho : 1
        let th = m_mapa.tileFisicoAlto  > 0 ? m_mapa.tileFisicoAlto  : 1
        let w = (cam.ancho - cam.inicioX) / tw + 23
        let h = ((cam.alto - cam.inicioY) / th) * 2 + 78
        return (p.x - 15, p.y - 5, w, h)
    }

    func seleccionarUnidadSiguiente() {
        guard !m_unidades.isEmpty else { return }

        // Centrar cámara en la unidad
        let u = m_unidades[m_indiceUnidadAEncontrar]
        m_camara.X = (((u.posicionEnTileFisico.y - u.posicionEnTileFisico.x) *
                        m_mapa.tileFisicoAncho) >> 1) + Video.Ancho / 2
        m_camara.Y = ((-(u.posicionEnTileFisico.y + u.posicionEnTileFisico.x) *
                        m_mapa.tileFisicoAlto) >> 1) + Video.Alto / 2

        m_unidadSeleccionada?.esSeleccionada = false
        m_grupoSeleccionado?.esSeleccionado  = false

        m_unidadSeleccionada = u
        m_unidadSeleccionada?.esSeleccionada = true
        m_hud.unidadSeleccionada = m_unidadSeleccionada

        m_indiceUnidadAEncontrar += 1
        if m_indiceUnidadAEncontrar >= m_unidades.count { m_indiceUnidadAEncontrar = 0 }
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

        m_objetoFlecha?.actualizar()
        m_cuenta += 1
    }

    // MARK: - Flecha de orientación

    private func actualizarFlechaOrientacion() {
        guard let ord = m_orden, let flecha = m_flechaOrientacion else { return }

        // Posición en pantalla del tile objetivo
        m_posOrdenApuntada.x = (((ord.punto.x - ord.punto.y) * m_mapa.tileAncho / 2) >> 1)
                              + m_camara.inicioX + m_camara.X
        m_posOrdenApuntada.y = (((ord.punto.x + ord.punto.y) * m_mapa.tileAlto  / 2) >> 1)
                              + m_camara.inicioY + m_camara.Y

        guard !objetivoEsVisible() else { return }

        let cx = Video.Ancho / 2
        let cy = Video.Alto  / 2
        let a  = Double(m_posOrdenApuntada.y - cy)
        let b  = Double(m_posOrdenApuntada.x - cx)

        var grados = atan(a / b) * 180 / .pi
        if a < 0 && b > 0  { grados = -grados }
        if a >= 0 && b < 0 { grados = 180 - grados }
        if a < 0  && b < 0 { grados = 180 - grados }
        if a > 0  && b >= 0 { grados = 360 - grados }

        let factor = 360.0 / 8
        let mitad  = 360.0 / 16

        let dir: Definiciones.DIRECCION
        if      (grados >= 0 && grados < mitad) || grados > 360 - mitad { dir = .E  }
        else if grados >= mitad          && grados < mitad + factor      { dir = .NE }
        else if grados >= mitad + factor && grados < mitad + factor * 2  { dir = .N  }
        else if grados >= mitad + factor * 2 && grados < mitad + factor * 3 { dir = .NO }
        else if grados >= mitad + factor * 3 && grados < mitad + factor * 4 { dir = .O  }
        else if grados >= mitad + factor * 4 && grados < mitad + factor * 5 { dir = .SO }
        else if grados >= mitad + factor * 5 && grados < mitad + factor * 6 { dir = .S  }
        else                                                                 { dir = .SE }

        let OFFSET = -20
        let fw = flecha.frameAncho
        let fh = flecha.frameAlto

        if m_posOrdenApuntada.x > m_camara.inicioX &&
           m_posOrdenApuntada.x < m_camara.ancho - fw + OFFSET {
            m_posicionFlechaOrientacion.x = m_posOrdenApuntada.x
        } else if m_posOrdenApuntada.x <= m_camara.inicioX {
            m_posicionFlechaOrientacion.x = -OFFSET
        } else {
            m_posicionFlechaOrientacion.x = m_camara.ancho - fw + OFFSET
        }

        if m_posOrdenApuntada.y > m_camara.inicioY &&
           m_posOrdenApuntada.y < m_camara.alto - fh + OFFSET {
            m_posicionFlechaOrientacion.y = m_posOrdenApuntada.y
        } else if m_posOrdenApuntada.y <= m_camara.inicioY {
            m_posicionFlechaOrientacion.y = -OFFSET
        } else {
            m_posicionFlechaOrientacion.y = m_camara.alto - fh + OFFSET
        }

        flecha.setearAnimacion(dir.rawValue)
    }

    private func objetivoEsVisible() -> Bool {
        return m_posOrdenApuntada.x > m_camara.inicioX &&
               m_posOrdenApuntada.x < m_camara.ancho   &&
               m_posOrdenApuntada.y > m_camara.inicioY  &&
               m_posOrdenApuntada.y < m_camara.alto
    }

    // MARK: - Unidad bajo el mouse

    private func obtenerUnidadBajoMouse() -> Unidad? {
        let rect = obtenerCoordenadasDePintado()
        var XX = rect.x, YY = rect.y
        let finI = rect.w, finJ = rect.h
        var tileY = 0, cambio = true

        while tileY <= finJ {
            var tileX = 0
            var i = XX, j = YY
            while tileX <= finI && j >= 0 {
                if i >= 0 && i < m_mapa.altoMapaFisico && j < m_mapa.anchoMapaFisico {
                    if let uni = m_objetosAPintar[i][j] as? Unidad,
                       uni.chequearSiEstaBajoElMouse() {
                        return uni
                    }
                }
                tileX += 1; i += 1; j -= 1
            }
            tileY += 1
            if cambio { XX += 1; cambio = false }
            else       { YY += 1; cambio = true  }
        }
        return nil
    }

    // MARK: - Órdenes

    private func chequearOrdenesAUnidades() {
        // Click izquierdo sobre una unidad argentina: seleccionarla
        if Mouse.Instancia.BotonesApretados.contains(Mouse.BOTON_IZQ) {
            if let uBajoMouse = m_unidadBajoMouse, uBajoMouse.bando == .ARGENTINO {
                let arr = Mouse.Instancia.RectanguloArrastrado
                let arrastrando = Mouse.Instancia.arrastrando()
                    && Int(arr.width) >= 4 && Int(arr.height) >= 4
                if !arrastrando {
                    borrarUnidadesSeleccionadas()
                    uBajoMouse.esSeleccionada = true
                    m_hud.unidadSeleccionada  = uBajoMouse
                    m_unidadSeleccionada      = uBajoMouse

                    if uBajoMouse.perteneceAUnGrupo {
                        uBajoMouse.grupoAlQuePertenezco?.eliminarUnidad(uBajoMouse)
                        uBajoMouse.salirDelGrupo()
                    }
                    Mouse.Instancia.soltarBoton(Mouse.BOTON_IZQ)
                }
            }
        }

        guard m_unidadSeleccionada != nil || m_grupoSeleccionado != nil else { return }

        // Click derecho: mover o atacar
        if Mouse.Instancia.BotonesApretados.contains(Mouse.BOTON_DER) {
            Mouse.Instancia.soltarBoton(Mouse.BOTON_DER)

            let tile = m_mapa.tileChicoMouse

            if m_mapa.esPosicionCaminable(tile.x, tile.y) {
                // Hay unidad enemiga bajo el mouse → atacar
                if let uBajoMouse = m_unidadBajoMouse,
                   uBajoMouse.bando == .ENEMIGO,
                   !uBajoMouse.estaMuerto() {
                    if let grupo = m_grupoSeleccionado {
                        grupo.atacar(uBajoMouse)
                    } else {
                        m_unidadSeleccionada?.atacar(uBajoMouse)
                    }
                } else {
                    // Mover
                    if let grupo = m_grupoSeleccionado {
                        grupo.mover(tile.x, tile.y)
                    } else {
                        m_unidadSeleccionada?.mover(tile.x, tile.y)
                    }
                    m_cuenta = 0
                    m_objetoFlecha?.setearPosicionEnTile(tile.x, tile.y)
                }
            } else {
                // Tile no caminable: chequear si es enfermería
                let tileBajoMouse = m_mapa.tileBajoMouse
                guard tileBajoMouse.y < m_mapa.alto  && tileBajoMouse.y >= 0 &&
                      tileBajoMouse.x < m_mapa.ancho && tileBajoMouse.x >= 0 else { return }

                let tileEdif = Int(m_mapa.capaEdificios[tileBajoMouse.x][tileBajoMouse.y])
                guard tileEdif != 0, let ts = m_mapa.obtenerTileset(tileEdif) else { return }

                let localId = tileEdif - Int(ts.primerGid)
                guard localId >= 0, localId < ts.tiles.count,
                      let tileProp = ts.tiles[localId],
                      ts.id == Int16(Res.TLS_INVALIDADO),
                      tileProp.id == Int16(Res.TILE_INVALIDADOS_ID_ENFERMERIA) else { return }

                Log.Instancia.debug("Me llevan a sanar.")
                if let grupo = m_grupoSeleccionado,
                   grupo.salud < grupo.puntosDeResistencia {
                    grupo.sanar(tile.x, tile.y)
                } else if let unidad = m_unidadSeleccionada,
                          unidad.salud < unidad.puntosDeResistencia {
                    unidad.sanar(tile.x, tile.y)
                }
            }
        }

        // Click izquierdo sin arrastrar: deseleccionar
        if Mouse.Instancia.BotonesApretados.contains(Mouse.BOTON_IZQ) {
            m_unidadesSeleccionadas.forEach { $0.esSeleccionada = false }
            borrarUnidadesSeleccionadas()
        }
    }

    // MARK: - Creación y gestión de grupos

    private func crearGrupos() {
        guard !m_unidadesSeleccionadas.isEmpty else { return }
        guard m_grupoSeleccionado == nil && m_unidadSeleccionada == nil else { return }

        if m_unidadesSeleccionadas.count > 1 {
            if m_grupos == nil { m_grupos = [] }

            for unidad in m_unidadesSeleccionadas {
                if unidad.perteneceAUnGrupo {
                    unidad.grupoAlQuePertenezco?.eliminarUnidad(unidad)
                    unidad.salirDelGrupo()
                }
            }

            m_grupoSeleccionado = Grupo(m_unidadesSeleccionadas)
            m_grupoSeleccionado?.esSeleccionado = true
            m_grupos!.append(m_grupoSeleccionado!)
        } else {
            m_unidadSeleccionada = m_unidadesSeleccionadas[0]
        }
    }

    private func actualizarGrupos() {
        guard let grupos = m_grupos, !grupos.isEmpty else { return }

        var paraEliminar: [Grupo] = []

        for grupo in grupos {
            grupo.actualizar()
            if grupo.estadoActual == .ESPERANDO_ORDEN && !grupo.esSeleccionado {
                paraEliminar.append(grupo)
            }
            if grupo.estadoActual == .ELIMINADO {
                if grupo === m_grupoSeleccionado {
                    m_grupoSeleccionado = nil
                    if grupo.cantidadDeSoldados == 1 {
                        m_unidadSeleccionada = grupo.obtenerUltimaUnidad()
                    }
                }
                paraEliminar.append(grupo)
            }
        }

        for grupo in paraEliminar {
            grupo.eliminarGrupo()
            m_grupos?.removeAll { $0 === grupo }
        }
    }

    // MARK: - Cursor

    private func actualizarCursor() {
        Mouse.Instancia.setearCursor(
            AdministradorDeRecursos.Instancia.obtenerImagen(Res.IMG_CURSOR))

        guard m_unidadSeleccionada != nil || m_grupoSeleccionado != nil else { return }

        if let uBajoMouse = m_unidadBajoMouse, uBajoMouse.bando == .ENEMIGO {
            Mouse.Instancia.setearCursor(
                AdministradorDeRecursos.Instancia.obtenerImagen(Res.IMG_CURSOR_ESPADA))
        }

        if let u = m_unidadSeleccionada, u.estaMuerto() {
            borrarUnidadesSeleccionadas()
        }

        let tileBajoMouse = m_mapa.tileBajoMouse
        guard tileBajoMouse.y < m_mapa.alto  && tileBajoMouse.y >= 0 &&
              tileBajoMouse.x < m_mapa.ancho && tileBajoMouse.x >= 0 else { return }

        let tileEdif = Int(m_mapa.capaEdificios[tileBajoMouse.x][tileBajoMouse.y])
        guard tileEdif != 0, let ts = m_mapa.obtenerTileset(tileEdif) else { return }

        let localId = tileEdif - Int(ts.primerGid)
        guard localId >= 0, localId < ts.tiles.count,
              let tileProp = ts.tiles[localId],
              ts.id == Int16(Res.TLS_INVALIDADO),
              tileProp.id == Int16(Res.TILE_INVALIDADOS_ID_ENFERMERIA) else { return }

        let needsHeal = (m_unidadSeleccionada.map { $0.salud < $0.puntosDeResistencia } ?? false)
                     || (m_grupoSeleccionado.map  { $0.salud < $0.puntosDeResistencia } ?? false)
        if needsHeal {
            Mouse.Instancia.setearCursor(
                AdministradorDeRecursos.Instancia.obtenerImagen(Res.IMG_CURSOR_ENFERMERIA))
        }
    }

    // MARK: - Objetivos

    private func actualizarObjetivos() {
        guard m_alguienCumplioLaOrden else { return }

        if m_orden?.id == .TOMAR_OBJETO {
            m_objetoATomar = nil
        }

        setearProximaOrden()

        if m_orden == nil {
            m_cumplioObjetivo = true
            Log.Instancia.debug("Se cumplio con el objetivo deseado!!!!!!!")
        }
    }

    // MARK: - Helpers privados

    private func calcularPrimerTileAPintar(_ x: Int, _ y: Int) -> (x: Int, y: Int) {
        let th = m_mapa.tileAlto > 0 ? m_mapa.tileAlto / 2 : 1
        let tw = m_mapa.tileAncho > 0 ? m_mapa.tileAncho / 2 : 1
        let a = -y / th
        var b =  x / tw
        if x > 0 { b += 1 }
        return (a - b - 4, a + b - 2)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
