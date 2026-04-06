//
//  Episodio.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Episodio.cs + Episodio.EstadoCargando.cs + Episodio.EstadoJugando.cs
//  + Episodio.EstadoMostrarIntroduccion.cs — active game session.
//

import Foundation
internal import CoreGraphics

class Episodio {

    // MARK: - Enums
    enum BANDO { case ENEMIGO, ARGENTINO }

    enum ESTADO: Int {
        case FIN = -1, CARGANDO, JUGANDO, MOSTRAR_INTRODUCCION, MOSTRAR_OBJETIVOS, GANO, PERDIO
    }

    // MARK: - Constants
    private static let CUENTA_HASTA_PREGUNTAR_REINICIAR = 50
    private static let CAJA_OBJETIVOS_ANCHO             = 600
    private static let CAJA_OBJETIVOS_ALTO              = 270
    private static let CAJA_OBJETIVOS_OFFSET_BOTON_Y    = 70

    // MARK: - Declarations
    private var m_boton:        Boton?
    private var m_botonAceptar: Boton?
    private var m_obstaculos:   [Obstaculo] = []
    private var m_nivelActual:  Nivel?
    private var m_nroNivel:     Int = 0
    private var m_objetosAPintar = TablaObjetos([[]])
    private var m_camara:       Camara?
    private var m_objetivo:     Objetivo?
    private var m_enemigo:      BandoEnemigo?
    private var m_jugador:      BandoArgentino?
    private var m_mapa:         Mapa?
    private var m_estado:       ESTADO = .CARGANDO
    private var m_hud:          Hud?
    private var m_cuenta:       Int = 0
    private var m_mostrarPopupObjetivo:        Bool = false
    private var m_mostrarRecordatorioObjetivo: Bool = false
    private var m_cuentaMostrarObjetivo:       Int = 0
    private var m_paginaActual:                Int = 0
    private var m_menuDeGameOver: MenuDeConfirmacion

    // Cheats
    private var m_cheatGanarIndice:   Int = 0
    private var m_cheatPerderIndice:  Int = 0
    private var m_cheatObjetivoIndice:Int = 0

    // MARK: - Properties
    var estado: ESTADO { m_estado }

    // MARK: - Initializer
    init() {
        m_menuDeGameOver = MenuDeConfirmacion(Res.STR_CONTINUARJUEGO, Res.STR_NO, Res.STR_SI)
        m_menuDeGameOver.setearPosicion(0, 0, Superficie.V_CENTRO | Superficie.H_CENTRO)
    }

    deinit { dispose() }

    func dispose() {
        m_mapa = nil
    }

    // MARK: - Public control

    func iniciar() {
        setearEstado(.CARGANDO)
    }

    func guardar() -> Bool { false }

    func salir() {}

    // MARK: - Update

    @discardableResult
    func actualizar() -> Bool {
        switch m_estado {
        case .CARGANDO:              actualizarEstadoCargado()
        case .MOSTRAR_INTRODUCCION:  actualizarEstadoMostrarIntroduccion()
        case .MOSTRAR_OBJETIVOS:     actualizarEstadoMostrarObjetivo()
        case .JUGANDO:               actualizarEstadoJugando()
        case .GANO:                  actualizarEstadoGano()
        case .PERDIO:                actualizarEstadoPerdio()
        case .FIN:                   break
        }
        return false
    }

    // MARK: - Draw

    func dibujar(_ g: Video) {
        switch m_estado {
        case .CARGANDO:             dibujarEstadoCargando(g)
        case .MOSTRAR_OBJETIVOS:    dibujarEstadoMostrarObjetivo(g)
        case .JUGANDO:              dibujarEstadoJugando(g)
        case .MOSTRAR_INTRODUCCION: dibujarEstadoMostrarIntroduccion(g)
        case .GANO:                 dibujarEstadoGano(g)
        case .PERDIO:               dibujarEstadoPerdio(g)
        case .FIN:                  break
        }
        g.setearColor(Definiciones.COLOR_BLANCO)
    }

    // MARK: - LOADING state

    private func actualizarEstadoCargado() {
        if cargarNivel(0) {
            actualizarEstadoJugando()
            setearNuevoObjetivo()
            Sonido.Instancia.parar(Res.SFX_SPLASH)
            Sonido.Instancia.reproducir(Res.SFX_BATALLA, -1)
            setearEstado(.MOSTRAR_INTRODUCCION)
        }
    }

    private func dibujarEstadoCargando(_ g: Video) {
        g.llenarRectangulo(0)
        g.setearColor(Definiciones.COLOR_TITULO)
        g.setearFuente(AdministradorDeRecursos.Instancia.fuentes[Definiciones.FUENTE_TITULO],
                       Definiciones.COLOR_TITULO)
        g.escribir(Res.STR_CARGANDO, 0, Definiciones.CARGANDO_Y, Superficie.H_CENTRO)
    }

    private func cargarSprites() {
        let sprs = AdministradorDeRecursos.Instancia.sprites
        if Res.SPR_PATRICIO < sprs.count { sprs[Res.SPR_PATRICIO]?.cargar() }
        if Res.SPR_INGLES   < sprs.count { sprs[Res.SPR_INGLES]?.cargar()   }
    }

    private func cargarObjetosAPintar() -> Bool {
        guard let mapa = m_mapa else { return false }

        m_objetosAPintar.tabla = Array(repeating: Array(repeating: nil, count: mapa.anchoMapaFisico),
                                       count: mapa.altoMapaFisico)
        m_obstaculos = []

        for i in 0..<mapa.alto {
            for j in 0..<mapa.ancho {
                let tileId = Int(mapa.capaObstaculos[i][j])
                guard tileId != 0 else { continue }
                guard let ts = mapa.obtenerTileset(tileId) else { continue }

                let localId = tileId - Int(ts.primerGid)
                let obs = Obstaculo(indice: localId, i: i * 2, j: j * 2, tileset: ts)
                m_obstaculos.append(obs)

                let fi = i * 2, fj = j * 2
                if fi < m_objetosAPintar.tabla.count, fj < m_objetosAPintar.tabla[fi].count {
                    m_objetosAPintar.tabla[fi][fj] = obs
                }
            }
        }
        return true
    }

    private func cargarNivel(_ nroNivel: Int) -> Bool {
        if m_cuenta == 0 {
            m_nroNivel = nroNivel
            m_hud      = Hud()
            let hudAlto = m_hud?.alto ?? 0
            m_camara   = Camara(x: 0, y: 0, alto: Video.Alto - hudAlto)
            m_mapa     = Mapa(camara: m_camara!)

        } else if m_cuenta == 1 {
            guard let mapa = m_mapa else { m_cuenta += 1; return false }
            if !mapa.cargar(Res.MAP_NIVEL1 + m_nroNivel) { return false }

            Objeto.mapa   = mapa
            Objeto.camara = m_camara

            let nivel = Nivel()
            nivel.cargar(m_nroNivel)
            m_nivelActual = nivel

        } else if m_cuenta == 2 {
            cargarSprites()

        } else if m_cuenta == 3 {
            m_boton       = Boton(leyenda: Res.STR_SIGUIENTE, fuente: nil)
            m_botonAceptar = Boton(leyenda: Res.STR_ACEPTAR, fuente: nil)
            AdministradorDeRecursos.Instancia.cargarTipoDeUnidades()

        } else if m_cuenta == 4 {
            if !cargarObjetosAPintar() { return false }

        } else if m_cuenta == 5 {
            guard let mapa = m_mapa, let camara = m_camara, let hud = m_hud else {
                m_cuenta += 1; return false
            }
            m_jugador = BandoArgentino(mapa: mapa, camara: camara,
                                       objetosAPintar: m_objetosAPintar, hud: hud)
            m_enemigo = BandoEnemigo(mapa: mapa, camara: camara,
                                     objetosAPintar: m_objetosAPintar, hud: hud)

        } else if m_cuenta == 6 {
            if !(m_jugador?.cargarUnidades(m_nroNivel) ?? true) { return false }

        } else if m_cuenta == 10 {
            if !(m_enemigo?.cargarUnidades(m_nroNivel) ?? true) { return false }
            m_cuenta += 1
            return true
        }

        m_cuenta += 1
        return false
    }

    // MARK: - SHOW INTRODUCTION state

    private func actualizarEstadoMostrarIntroduccion() {
        if m_cuenta == 0 {
            m_boton?.setearPosicion(0, Definiciones.BOTON_OBJETIVOS_Y, Superficie.H_CENTRO)
        }
        m_cuenta += 1
        if m_boton?.actualizar() != 0 {
            m_paginaActual += 1
            if m_paginaActual == Definiciones.PAGINAS_POR_INTRO - 1 {
                setearEstado(.JUGANDO)
            }
        }
    }

    private func setearNuevoObjetivo() {
        Log.Instancia.debug("Le seteo un nuevo objetivo.........")
        m_mostrarPopupObjetivo = true
        let batallaActual = m_nivelActual?.nroBatallaActual ?? 0
        m_objetivo = m_nivelActual?.proximoObjetivo()

        if (m_nivelActual?.nroBatallaActual ?? 0) != batallaActual {
            Log.Instancia.debug("Pase del nivelllllllll")
            setearEstado(.MOSTRAR_INTRODUCCION)
        }
        m_mostrarPopupObjetivo  = true
        m_cuentaMostrarObjetivo = 0

        m_jugador?.setearObjetivo(m_objetivo)

        if m_objetivo == nil {
            setearEstado(.GANO)
        }
    }

    private func dibujarEstadoMostrarIntroduccion(_ g: Video) {
        dibujarEstadoJugando(g)

        g.setearColor(Definiciones.COLOR_OBJETIVOS)
        let hudAlto = m_hud?.alto ?? 0
        g.llenarRectangulo(0, -(hudAlto >> 1),
                           Video.Ancho - (Definiciones.BORDE_OBJETIVOS << 1),
                           Video.Alto  - (Definiciones.BORDE_OBJETIVOS << 1) - hudAlto,
                           Definiciones.ALPHA_OBJETIVOS,
                           Superficie.V_CENTRO | Superficie.H_CENTRO)

        if m_paginaActual == 0 {
            g.setearFuente(AdministradorDeRecursos.Instancia.fuentes[Definiciones.FUENTE_TITULO_OBJETIVOS],
                           Definiciones.GUI_COLOR_TEXTO)
        } else {
            g.setearFuente(AdministradorDeRecursos.Instancia.fuentes[Definiciones.FUENTE_OBJETIVOS],
                           Definiciones.GUI_COLOR_TEXTO)
        }

        let strIdx = Res.STR_PRIMER_BATALLA + m_paginaActual +
                     ((m_nivelActual?.nroBatallaActual ?? 0) * Definiciones.PAGINAS_POR_INTRO)
        g.escribir(strIdx, 0, -(hudAlto >> 1), Superficie.V_CENTRO | Superficie.H_CENTRO)
        m_boton?.dibujar(g)
    }

    // MARK: - SHOW OBJECTIVES state

    private func actualizarEstadoMostrarObjetivo() {
        if m_cuenta == 0 {
            m_botonAceptar?.setearPosicion(0, Episodio.CAJA_OBJETIVOS_OFFSET_BOTON_Y,
                                           Superficie.H_CENTRO | Superficie.V_CENTRO)
        }
        m_cuenta += 1
        if m_botonAceptar?.actualizar() != 0 {
            m_paginaActual += 1
            if m_paginaActual == Definiciones.PAGINAS_POR_INTRO {
                setearEstado(.JUGANDO)
                m_mostrarPopupObjetivo        = false
                m_mostrarRecordatorioObjetivo = true
            }
        }
    }

    private func dibujarEstadoMostrarObjetivo(_ g: Video) {
        dibujarEstadoJugando(g)

        let hudAlto = m_hud?.alto ?? 0
        g.setearColor(Definiciones.COLOR_OBJETIVOS)
        g.llenarRectangulo(0, -(hudAlto / 2),
                           Episodio.CAJA_OBJETIVOS_ANCHO, Episodio.CAJA_OBJETIVOS_ALTO,
                           Definiciones.ALPHA_OBJETIVOS,
                           Superficie.V_CENTRO | Superficie.H_CENTRO)

        g.setearFuente(AdministradorDeRecursos.Instancia.fuentes[Definiciones.FUENTE_TITULO],
                       Definiciones.GUI_COLOR_TEXTO)
        g.escribir(Res.STR_OBJETIVOS, 0,
                   -(hudAlto / 2) - Episodio.CAJA_OBJETIVOS_ALTO / 2 + 50,
                   Superficie.V_CENTRO | Superficie.H_CENTRO)

        g.setearFuente(AdministradorDeRecursos.Instancia.fuentes[Definiciones.FUENTE_OBJETIVOS],
                       Definiciones.GUI_COLOR_TEXTO)
        let strIdx = Res.STR_PRIMER_BATALLA + m_paginaActual +
                     ((m_nivelActual?.nroBatallaActual ?? 0) * Definiciones.PAGINAS_POR_INTRO)
        g.escribir(strIdx, 0, -(hudAlto >> 1) + 30, Superficie.V_CENTRO | Superficie.H_CENTRO)

        m_botonAceptar?.dibujar(g)
    }

    // MARK: - PLAYING state

    private func actualizarEstadoJugando() {
        if m_mostrarPopupObjetivo { m_cuentaMostrarObjetivo += 1 }

        if Definiciones.CHEATS_HABILITADOS { chequearCheats() }

        m_mapa?.actualizar()

        // Reset visibility layer
        if let mapa = m_mapa {
            mapa.capaTilesVisibles = Array(repeating: Array(repeating: 0, count: mapa.anchoMapaFisico),
                                           count: mapa.altoMapaFisico)
        }

        m_jugador?.actualizar()
        m_enemigo?.actualizar()

        m_hud?.cantidadArgentinos = m_jugador?.cantidadDeUnidades ?? 0
        m_hud?.cantidadEnemigos   = m_enemigo?.cantidadDeUnidades ?? 0

        chequearFinDeJuego()

        m_hud?.actualizar()
        actualizarOrdenes()

        m_obstaculos.forEach { $0.actualizar() }
    }

    private func chequearFinDeJuego() {
        if (m_jugador?.cantidadDeUnidades ?? 1) == 0 {
            setearEstado(.PERDIO)
        }
    }

    private func actualizarOrdenes() {
        if m_jugador?.cumplioObjetivo() == true {
            Log.Instancia.debug("Felicitaciones!! cumpliste el objetivo.....")
            setearNuevoObjetivo()
        }
    }

    private func dibujarEstadoJugando(_ g: Video) {
        g.llenarRectangulo(Definiciones.COLOR_NEGRO)

        if let mapa = m_mapa { m_mapa?.dibujarCapa(g, mapa.CAPA_TERRENO) }

        dibujarObjetos(g)

        dibujarCapaSemitransparente(g)

        m_hud?.dibujar(g)

        m_jugador?.dibujarFlechaOrientacion(g)

        if m_mostrarPopupObjetivo &&
           m_cuentaMostrarObjetivo > Definiciones.CUENTA_MOSTRAR_OBJETIVO_INICIO {
            setearEstado(.MOSTRAR_OBJETIVOS)
        } else if m_mostrarRecordatorioObjetivo &&
                  m_cuentaMostrarObjetivo > Definiciones.CUENTA_MOSTRAR_OBJETIVO_INICIO {
            let hudAlto = m_hud?.alto ?? 0
            let camAlto = m_camara?.alto ?? Video.Alto
            g.setearFuente(AdministradorDeRecursos.Instancia.fuentes[Definiciones.FUENTE_RECORDATORIO_OBJETIVOS],
                           Definiciones.COLOR_FUENTE_OBJETIVOS)
            g.escribir(Res.STR_OBJETIVOS,
                       Definiciones.OFFSET_OBJETIVOS << 1,
                       camAlto - (Definiciones.ALTO_OBJETIVOS + Definiciones.OFFSET_OBJETIVOS * 2) - 10, 0)
            let strIdx = Res.STR_OBJETIVO_BATALLA_1_1 + (m_nivelActual?.cantidadDeObjetivosCumplidos ?? 0)
            g.escribir(strIdx,
                       Definiciones.OFFSET_OBJETIVOS << 1,
                       camAlto - (Definiciones.ALTO_OBJETIVOS + Definiciones.OFFSET_OBJETIVOS * 2) + 5, 0)
            _ = hudAlto  // suppress warning
        }

        if Mouse.Instancia.arrastrando() {
            g.setearColor(Definiciones.COLOR_VERDE)
            let r = Mouse.Instancia.RectanguloArrastrado
            g.dibujarRectangulo(Int(r.minX), Int(r.minY), Int(r.width), Int(r.height), 0)
        }
    }

    private func dibujarCapaSemitransparente(_ g: Video) {
        guard let mapa = m_mapa, let camara = m_camara, let jugador = m_jugador else { return }

        let oldClip = g.obtenerClip()
        g.setearClip(camara.inicioX, camara.inicioY, camara.ancho, camara.alto)

        let rect = jugador.obtenerCoordenadasDePintado()
        var XX   = rect.x
        var YY   = rect.y
        let finI = rect.w
        let finJ = rect.h

        var tileY = 0
        var cambio = true

        while tileY <= finJ {
            var tileX = 0
            var i = XX, j = YY
            while tileX <= finI && j >= 0 {
                if i >= 0 && i < mapa.altoMapaFisico && j < mapa.anchoMapaFisico {
                    if mapa.capaTilesVisibles[i][j] == 0 {
                        mapa.dibujarTileChico(g, i, j, true)
                    }
                }
                tileX += 1; i += 1; j -= 1
            }
            tileY += 1
            if cambio { XX += 1; cambio = false }
            else       { YY += 1; cambio = true  }
        }

        g.setearClip(oldClip.x, oldClip.y, oldClip.w, oldClip.h)
    }

    private func dibujarObjetos(_ g: Video) {
        guard let mapa = m_mapa, let camara = m_camara, let jugador = m_jugador else { return }

        let oldClip = g.obtenerClip()
        g.setearClip(camara.inicioX, camara.inicioY, camara.ancho, camara.alto)

        let rect = jugador.obtenerCoordenadasDePintado()
        var XX   = rect.x
        var YY   = rect.y
        let finI = rect.w
        let finJ = rect.h

        var tileY = 0
        var cambio = true

        while tileY <= finJ {
            var tileX = 0
            var i = XX, j = YY
            while tileX <= finI && j >= 0 {
                if i >= 0 && i < mapa.altoMapaFisico && j < mapa.anchoMapaFisico {
                    if let obj = m_objetosAPintar.tabla[i][j] {
                        if let uni = obj as? Unidad  { uni.dibujar(g) }
                        if let obs = obj as? Obstaculo { obs.dibujar(g) }
                    }
                }
                tileX += 1; i += 1; j -= 1
            }
            tileY += 1
            if cambio { XX += 1; cambio = false }
            else       { YY += 1; cambio = true  }
        }

        // Fueguitos del jugador se dibujan encima (delegado a BandoArgentino via Jugador)
        // m_jugador.Dibujar(g) — in the original it drew fire effects; delegated if needed

        g.setearClip(oldClip.x, oldClip.y, oldClip.w, oldClip.h)
    }

    // MARK: - WON state

    private func actualizarEstadoGano() {
        if m_boton?.actualizar() != 0 {
            setearEstado(.FIN)
        }
    }

    private func dibujarEstadoGano(_ g: Video) {
        dibujarEstadoJugando(g)
        m_boton?.dibujar(g)
        g.setearFuente(AdministradorDeRecursos.Instancia.fuentes[Definiciones.FUENTE_GANO],
                       Definiciones.COLOR_TEXTO_GANO)
        g.escribir(Res.STR_GANASTE, 0, 0, Superficie.H_CENTRO | Superficie.V_CENTRO)
    }

    // MARK: - LOST state

    private func actualizarEstadoPerdio() {
        m_cuenta += 1
        guard m_cuenta > Episodio.CUENTA_HASTA_PREGUNTAR_REINICIAR else { return }

        let resultado = m_menuDeGameOver.actualizar()
        if resultado == MenuDeConfirmacion.SELECCION.IZQUIERDO.rawValue {
            setearEstado(.FIN)
        }
        if resultado == MenuDeConfirmacion.SELECCION.DERECHO.rawValue {
            setearEstado(.CARGANDO)
        }
    }

    private func dibujarEstadoPerdio(_ g: Video) {
        dibujarEstadoJugando(g)
        g.setearFuente(AdministradorDeRecursos.Instancia.fuentes[Definiciones.FUENTE_GANO],
                       Definiciones.COLOR_TEXTO_GANO)
        g.escribir(Res.STR_PERDISTE, 0, -100, Superficie.H_CENTRO | Superficie.V_CENTRO)
        if m_cuenta > Episodio.CUENTA_HASTA_PREGUNTAR_REINICIAR {
            m_menuDeGameOver.dibujar(g)
        }
    }

    // MARK: - Cheats

    private func chequearCheats() {
        let teclas = Teclado.Instancia.TeclasApretadas

        if teclas.contains(Teclado.TECLA_G) && m_cheatGanarIndice == 0 {
            m_cheatGanarIndice += 1
        } else if teclas.contains(Teclado.TECLA_A) && m_cheatGanarIndice == 1 {
            m_cheatGanarIndice += 1
        } else if teclas.contains(Teclado.TECLA_N) && m_cheatGanarIndice == 2 {
            m_cheatGanarIndice += 1
        } else if teclas.contains(Teclado.TECLA_X) && m_cheatGanarIndice == 3 {
            m_cheatGanarIndice += 1
        } else if teclas.contains(Teclado.TECLA_W) && m_cheatGanarIndice == 4 {
            setearEstado(.GANO); m_cheatGanarIndice = 0
        } else if teclas.contains(Teclado.TECLA_P) && m_cheatPerderIndice == 0 {
            m_cheatPerderIndice += 1
        } else if teclas.contains(Teclado.TECLA_E) && m_cheatPerderIndice == 1 {
            m_cheatPerderIndice += 1
        } else if teclas.contains(Teclado.TECLA_R) && m_cheatPerderIndice == 2 {
            m_cheatPerderIndice += 1
        } else if teclas.contains(Teclado.TECLA_X) && m_cheatPerderIndice == 3 {
            m_cheatPerderIndice += 1
        } else if teclas.contains(Teclado.TECLA_W) && m_cheatPerderIndice == 4 {
            setearEstado(.PERDIO); m_cheatPerderIndice = 0
        } else if teclas.contains(Teclado.TECLA_O) && m_cheatObjetivoIndice == 0 {
            m_cheatObjetivoIndice += 1
        } else if teclas.contains(Teclado.TECLA_B) && m_cheatObjetivoIndice == 1 {
            m_cheatObjetivoIndice += 1
        } else if teclas.contains(Teclado.TECLA_J) && m_cheatObjetivoIndice == 2 {
            m_cheatObjetivoIndice += 1
        } else if teclas.contains(Teclado.TECLA_X) && m_cheatObjetivoIndice == 3 {
            m_cheatObjetivoIndice += 1
        } else if teclas.contains(Teclado.TECLA_W) && m_cheatObjetivoIndice == 4 {
            setearNuevoObjetivo(); m_cheatObjetivoIndice = 0
        } else if !teclas.isEmpty {
            if teclas.contains(Teclado.TECLA_U) { m_jugador?.seleccionarUnidadSiguiente() }
            Log.Instancia.debug("Reseteo todos los cheats--")
            m_cheatObjetivoIndice = 0
            m_cheatGanarIndice    = 0
            m_cheatPerderIndice   = 0
        }
        Teclado.Instancia.limpiarTeclas()
    }

    // MARK: - Private

    private func setearEstado(_ estado: ESTADO) {
        m_cuenta       = 0
        m_estado       = estado
        m_paginaActual = 0
        if estado == .MOSTRAR_OBJETIVOS { m_paginaActual = 2 }
    }
}
