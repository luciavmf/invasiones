// Nivel/Unidades/Unidad.swift
// Puerto de Unidad.cs (varios archivos parciales fusionados) — representa una unidad en el juego.

import Foundation

class Unidad: Objeto {

    // MARK: - Constantes
    static let MAXIMA_VISIBILIDAD            = 15
    static let DISTANCIA_A_CHEQUEAR_COLISION = 4

    private let RANDOM_PATRULLA_MAX = 16
    private let RANDOM_PATRULLA_MIN = 8
    private let CANTIDAD_MINIMA_TILES_ORD_MOVER = 3
    private let SELECCION_ANCHO   = 20
    private let SELECCION_Y       = -3
    private let CUENTA_FRAME_MUERTO = 150

    // MARK: - Enums
    enum ESTADO {
        case OCIO, MOVIENDO, MURIENDO, ATACANDO, PERSIGUIENDO_UNIDAD, MUERTO, PATRULLANDO, SANANDO
    }

    enum SUBESTADO {
        case INCREMENTAR_PASO, ESQUIVAR_UNIDAD, ALCANZAR_PASO, TERMINO_DE_DAR_PASO
    }

    // MARK: - Atributos
    private var m_tipo:                   Int = 0
    private var m_subestado:              SUBESTADO = .INCREMENTAR_PASO
    private var m_bando:                  Episodio.BANDO = .ENEMIGO
    private var m_unidadAEsquivar:        Unidad?
    private var m_salud:                  Int = 100
    private var m_puntosDeResistencia:    Int = 100
    private var m_puntosDeAtaque:         Int = 10
    private var m_visibilidad:            Int = 10
    private var m_punteria:               Int = 5
    private var m_alcanceDeTiro:          Int = 5
    private var m_intervaloEntreAtaques:  Int = 30
    private var m_velocidadActual:        (x: Int, y: Int) = (2, 2)
    private var m_velocidadPorDefecto:    (x: Int, y: Int) = (2, 2)
    private var m_enemigo:               Unidad?
    private var m_estado:                ESTADO = .OCIO
    private var m_proximoEstado:         ESTADO = .OCIO
    private var m_direccion:             Int = 0  // 0=N, 1=NE, 2=E, 3=SE, 4=S, 5=SO, 6=O, 7=NO
    private var m_caminoASeguir:         [(i: Int, j: Int)]? = nil
    private var m_proximoTile:           (x: Int, y: Int) = (0, 0)
    private var m_proximoPaso:           (x: Int, y: Int) = (0, 0)
    private var m_seleccionado:          Bool = false
    private var m_modo:                  Int = 0
    private var m_sprite:                Sprite?
    private var m_cuenta:                Int = 0
    private var m_blanco:                (x: Int, y: Int) = (-1, -1)
    private var m_nombre:                String = ""
    private var m_avatar:                Superficie?
    private var m_orden:                 Orden?
    private var m_ordenDeObjetivo:       Orden?
    private var m_cumplioConLaOrden:     Bool = false
    private var m_posicionDePatrulla:    (x: Int, y: Int) = (0, 0)
    private var m_posicionDeseada:       (x: Int, y: Int) = (0, 0)  // offset en formación
    private var m_primerSprite:          Int = 0
    private var m_ticksEntreCadaRecuperacion: Int = 50
    private var m_puntosDeRecuperacion:  Int = 20
    private var m_cuentaRecuperacion:    Int = 0
    private var m_esComandante:          Bool = false
    private var m_grupo:                 Grupo?
    private var m_cumplioConLaOrdenDeObjetivo: Bool = false

    // Posición continua en mundo para movimiento suave
    private var m_posXActual:   Double = 0
    private var m_posYActual:   Double = 0

    // MARK: - Properties públicas

    var bando: Episodio.BANDO {
        get { m_bando }
        set { m_bando = newValue }
    }

    var estadoActual: ESTADO { m_estado }

    var esSeleccionada: Bool {
        get { m_seleccionado }
        set { m_seleccionado = newValue }
    }

    var puntosDeAtaque:     Int { m_puntosDeAtaque     }
    var salud:              Int { m_salud               }
    var puntosDeResistencia:Int { m_puntosDeResistencia }
    var alcance:            Int { m_alcanceDeTiro        }
    var visibilidad:        Int { m_visibilidad          }
    var velocidad:          (x: Int, y: Int) { m_velocidadActual }
    var velocidadPorDefecto:Int { m_velocidadPorDefecto.x }
    var intervaloEntreAtaques: Int { m_intervaloEntreAtaques }
    var punteria:           Int { m_punteria }
    var avatar:             Superficie? { m_avatar }
    var nombre:             String { m_nombre }
    var cumplioOrden:       Bool { m_cumplioConLaOrden }
    var proximoTile:        (x: Int, y: Int) { m_proximoTile }
    var offsetEnFormacion:  (x: Int, y: Int) {
        get { m_posicionDeseada }
        set { m_posicionDeseada = newValue }
    }
    var unidadAEsquivar: Unidad? { m_unidadAEsquivar }
    var caminoASeguir: [(i: Int, j: Int)]? { m_caminoASeguir }

    // MARK: - Constructores

    override init() {
        super.init()
    }

    /// Constructor de copia de template (id = índice en tipoDeUnidades).
    init(_ id: Int) {
        super.init()
        let tipos = AdministradorDeRecursos.Instancia.tipoDeUnidades
        guard id >= 0, id < tipos.count, let copia = tipos[id] else {
            Log.Instancia.debug("La copia de la unidad no esta cargada: id=\(id)")
            return
        }
        m_tipo                    = copia.m_tipo
        m_velocidadActual         = copia.m_velocidadActual
        m_velocidadPorDefecto     = copia.m_velocidadActual
        m_salud                   = copia.m_puntosDeResistencia
        m_puntosDeResistencia     = copia.m_puntosDeResistencia
        m_puntosDeAtaque          = copia.m_puntosDeAtaque
        m_visibilidad             = copia.m_visibilidad
        m_punteria                = copia.m_punteria
        m_alcanceDeTiro           = copia.m_alcanceDeTiro
        m_intervaloEntreAtaques   = copia.m_intervaloEntreAtaques
        m_avatar                  = copia.m_avatar
        m_nombre                  = copia.m_nombre
        m_ticksEntreCadaRecuperacion = copia.m_ticksEntreCadaRecuperacion
        m_puntosDeRecuperacion    = copia.m_puntosDeRecuperacion

        // Clone sprite
        if let s = copia.m_sprite {
            m_sprite = Sprite(copia: s)
        }
    }

    // MARK: - Update principal

    /// Actualiza la unidad. Devuelve true si cambió su posición en el mapa físico.
    @discardableResult
    override func actualizar() -> Bool {
        guard m_estado != .MUERTO else { return false }

        var movioEnMapa = false
        m_cumplioConLaOrden = false

        switch m_estado {
        case .OCIO:
            actualizarAnimacionEnOcio()
        case .MOVIENDO:
            movioEnMapa = actualizarEstadoMoviendo()
        case .PATRULLANDO:
            movioEnMapa = actualizarEstadoMoviendo()
        case .PERSIGUIENDO_UNIDAD:
            actualizarEstadoPersiguiendoUnidad()
        case .ATACANDO:
            actualizarEstadoAtacando()
        case .MURIENDO:
            actualizarEstadoMuriendo()
        case .MUERTO:
            break
        case .SANANDO:
            actualizarEstadoSanando()
        }

        // Chequear si cumplió la orden de objetivo
        chequearSiCumplioOrden()

        super.actualizar()
        dibujarSpriteActual()
        return movioEnMapa
    }

    override func dibujar(_ g: Video) {
        // La selección (barra de salud) se dibuja aquí
        if m_seleccionado {
            let healthFraction = Double(m_salud) / Double(max(m_puntosDeResistencia, 1))
            let barAncho = Int(Double(SELECCION_ANCHO) * healthFraction)
            g.setearColor(Definiciones.COLOR_VERDE)
            g.llenarRectangulo(m_x - SELECCION_ANCHO / 2,
                               m_y + SELECCION_Y,
                               barAncho, 3)
            g.setearColor(Definiciones.COLOR_ROJO)
            g.llenarRectangulo(m_x - SELECCION_ANCHO / 2 + barAncho,
                               m_y + SELECCION_Y,
                               SELECCION_ANCHO - barAncho, 3)
        }
        m_sprite?.dibujar(g, m_x - (m_sprite?.frameAncho ?? 0) / 2,
                           m_y - (m_sprite?.frameAlto ?? 0))
    }

    // MARK: - Órdenes públicas

    func mover(_ x: Int, _ y: Int) {
        m_orden = Orden(.MOVER, x, y)
        setearEstado(.MOVIENDO)
        m_proximoEstado = .OCIO

        let camino = PathFinder.Instancia.encontrarCaminoMasCorto(
            m_posEnTileFisico.x, m_posEnTileFisico.y, x, y)

        if let c = camino, !c.isEmpty {
            // El primer elemento es destino, último es origen. Usamos como pila (popLast = próximo paso).
            m_caminoASeguir = Array(c.dropLast())   // quita el nodo inicio (último = origen)
        } else {
            setearEstado(.OCIO)
            m_caminoASeguir = nil
            return
        }

        m_subestado = .INCREMENTAR_PASO
    }

    func patrullar() {
        setearEstado(.PATRULLANDO)
        m_proximoEstado = .PATRULLANDO
        m_posicionDePatrulla = m_posEnTileFisico
        m_caminoASeguir = encontrarCaminoParaPatrullarAlAzar(
            m_posEnTileFisico.x, m_posEnTileFisico.y)
    }

    func atacar(_ enemigo: Unidad) {
        m_enemigo = enemigo
        m_blanco  = (-1, -1)
        setearEstado(.PERSIGUIENDO_UNIDAD)
    }

    func parar() {
        setearEstado(.OCIO)
        m_caminoASeguir = nil
    }

    func setearOrdenDeObjetivo(_ ord: Orden?) {
        m_cumplioConLaOrden = false
        m_ordenDeObjetivo   = ord
    }

    func recuperarSalud() {
        setearEstado(.SANANDO)
    }

    // MARK: - Colisión y evasión

    func hayColision(_ otra: Unidad) -> Bool {
        let dx = abs(m_posEnTileFisico.x - otra.m_posEnTileFisico.x)
        let dy = abs(m_posEnTileFisico.y - otra.m_posEnTileFisico.y)
        return dx < 2 && dy < 2
    }

    func esquivarUnidad(_ otra: Unidad, _ visibles: [Unidad]?) {
        m_unidadAEsquivar = otra
        m_subestado       = .ESQUIVAR_UNIDAD
    }

    // MARK: - Consultas

    func estaMuerto() -> Bool { m_estado == .MUERTO }

    func seEstaMoviendo() -> Bool {
        return m_estado == .MOVIENDO || m_estado == .PATRULLANDO || m_estado == .PERSIGUIENDO_UNIDAD
    }

    func esVisibleEnPantalla() -> Bool {
        guard let cam = Objeto.camara else { return false }
        return m_x >= cam.inicioX && m_x <= cam.inicioX + cam.ancho &&
               m_y >= cam.inicioY && m_y <= cam.inicioY + cam.alto
    }

    func calcularDistancia(_ toI: Int, _ toJ: Int) -> Double {
        let di = Double(m_posEnTileFisico.x - toI)
        let dj = Double(m_posEnTileFisico.y - toJ)
        return sqrt(di * di + dj * dj)
    }

    func cumplioOrdenObjetivoMover() -> Bool {
        guard let ord = m_ordenDeObjetivo else { return false }
        let dist = calcularDistancia(ord.punto.x, ord.punto.y)
        return dist <= Double(CANTIDAD_MINIMA_TILES_ORD_MOVER)
    }

    // MARK: - Grupo / formación

    var perteneceAUnGrupo: Bool { m_grupo != nil }
    var grupoAlQuePertenezco: Grupo? { m_grupo }

    func adherirmeAGrupo(_ grupo: Grupo) {
        m_grupo = grupo
    }

    func salirDelGrupo() {
        m_grupo = nil
    }

    func marcarComoComandante() {
        m_esComandante = true
    }

    func desmarcarComandante() {
        m_esComandante = false
    }

    func calcularCaminoADistancia(_ caminoComandante: [(i: Int, j: Int)],
                                  _ offsetX: Int, _ offsetY: Int) {
        // Simplificado: calculamos nuestro camino directo al destino del comandante + offset
        guard let ultimo = caminoComandante.first else { return }
        let destI = ultimo.i + offsetX
        let destJ = ultimo.j + offsetY
        mover(destI, destJ)
    }

    func chequearSiEstaBajoElMouse() -> Bool {
        let mx = Int(Mouse.Instancia.X)
        let my = Int(Mouse.Instancia.Y)
        let fw = m_sprite?.frameAncho ?? (m_frameAncho > 0 ? m_frameAncho : 20)
        let fh = m_sprite?.frameAlto  ?? (m_frameAlto  > 0 ? m_frameAlto  : 30)
        let hw = fw / 2
        return mx >= m_x - hw && mx <= m_x + hw && my >= m_y - fh && my <= m_y
    }

    func sanar(_ x: Int, _ y: Int) {
        m_orden = Orden(.SANAR, x, y)
        setearEstado(.MOVIENDO)
        m_proximoEstado = .SANANDO

        let camino = PathFinder.Instancia.encontrarCaminoMasCorto(
            m_posEnTileFisico.x, m_posEnTileFisico.y, x, y)

        if let c = camino, !c.isEmpty {
            m_caminoASeguir = Array(c.dropLast())
        } else {
            Log.Instancia.debug("No se encontro el camino para sanar...")
            setearEstado(.OCIO)
            m_caminoASeguir = nil
            return
        }
        m_subestado = .INCREMENTAR_PASO
    }

    // MARK: - Selección por arrastre de mouse (rectangle)
    func seleccionarSiEstaEnRectangulo(_ x: Int, _ y: Int, _ w: Int, _ h: Int) -> Bool {
        let dentro = m_x >= x && m_x <= x + w && m_y >= y && m_y <= y + h
        if dentro { m_seleccionado = true }
        return dentro
    }

    // MARK: - Privados

    private func setearEstado(_ e: ESTADO) {
        m_estado = e
        m_cuenta = 0
        if e == .OCIO {
            m_caminoASeguir = nil
        }
    }

    private func actualizarAnimacionEnOcio() {
        m_sprite?.actualizar()
        let anim = primerAnimacion() + m_direccion
        m_sprite?.setearAnimacion(anim)
        m_sprite?.reproducir()
    }

    private func dibujarSpriteActual() {
        m_sprite?.actualizar()
    }

    private func primerAnimacion() -> Int {
        switch m_estado {
        case .OCIO, .PATRULLANDO, .SANANDO:
            return m_tipo == 0 ? Res.SPR_ANIM_PATRICIO_QUIETO_N : Res.SPR_ANIM_INGLES_QUIETO_N
        case .MOVIENDO, .PERSIGUIENDO_UNIDAD:
            return m_tipo == 0 ? Res.SPR_ANIM_PATRICIO_CAMINA_N : Res.SPR_ANIM_INGLES_CAMINA_N
        case .MURIENDO, .MUERTO:
            return m_tipo == 0 ? Res.SPR_ANIM_PATRICIO_MUERE_N : Res.SPR_ANIM_INGLES_MUERE_N
        case .ATACANDO:
            return m_tipo == 0 ? Res.SPR_ANIM_PATRICIO_ATACA_N : Res.SPR_ANIM_INGLES_ATACA_N
        }
    }

    // MARK: - Movimiento

    private func actualizarEstadoMoviendo() -> Bool {
        return moverse()
    }

    private func moverse() -> Bool {
        switch m_subestado {
        case .INCREMENTAR_PASO:
            guard let camino = m_caminoASeguir, !camino.isEmpty else {
                setearEstado(m_proximoEstado)
                m_caminoASeguir = nil
                return false
            }
            m_proximoTile = (camino.last!.i, camino.last!.j)
            m_caminoASeguir!.removeLast()
            m_proximoPaso = transformarIJEnXY(m_proximoTile.x, m_proximoTile.y)
            m_subestado   = .ALCANZAR_PASO

        case .ESQUIVAR_UNIDAD:
            recalcularProximoPaso()
            m_subestado = .ALCANZAR_PASO
            return true

        default: break
        }

        m_velocidadActual = (0, 0)
        let dir = obtenerDireccion(m_proximoPaso.x, m_proximoPaso.y)
        if dir != -1 { m_direccion = dir }

        // Actualiza animación de caminar
        let anim = primerAnimacion() + m_direccion
        m_sprite?.setearAnimacion(anim)
        m_sprite?.reproducir()

        let llego = moverseHaciaProximoPaso()

        if llego {
            let viejo = m_posEnTileFisico
            m_posEnTileAnterior = viejo
            m_posEnTileFisico   = m_proximoTile
            m_subestado         = .INCREMENTAR_PASO
            return true
        }
        return false
    }

    private func moverseHaciaProximoPaso() -> Bool {
        let spd = m_velocidadPorDefecto.x

        let dx = m_proximoPaso.x - m_posEnMundoPlano.x
        let dy = m_proximoPaso.y - m_posEnMundoPlano.y
        let dist = sqrt(Double(dx * dx + dy * dy))

        if dist <= Double(spd) {
            m_posEnMundoPlano = m_proximoPaso
            return true
        }

        let ratio = Double(spd) / dist
        m_posEnMundoPlano.x += Int(Double(dx) * ratio)
        m_posEnMundoPlano.y += Int(Double(dy) * ratio)
        return false
    }

    private func recalcularProximoPaso() {
        guard let otra = m_unidadAEsquivar, let mapa = Objeto.mapa else {
            m_subestado = .INCREMENTAR_PASO
            return
        }
        // Buscar un paso alternativo evitando la posición de la otra unidad
        let oI = otra.m_posEnTileFisico.x
        let oJ = otra.m_posEnTileFisico.y
        let offsets = [(-1, 0), (0, -1), (1, 0), (0, 1), (-1, -1), (1, 1), (-1, 1), (1, -1)]
        for (di, dj) in offsets {
            let ni = m_posEnTileFisico.x + di
            let nj = m_posEnTileFisico.y + dj
            if ni != oI || nj != oJ, mapa.esPosicionCaminable(ni, nj) {
                m_proximoTile = (ni, nj)
                m_proximoPaso = transformarIJEnXY(ni, nj)
                m_unidadAEsquivar = nil
                return
            }
        }
        m_subestado = .INCREMENTAR_PASO
    }

    private func obtenerDireccion(_ targetX: Int, _ targetY: Int) -> Int {
        let dx = targetX - m_posEnMundoPlano.x
        let dy = targetY - m_posEnMundoPlano.y
        if dx == 0 && dy == 0 { return -1 }

        let angle = atan2(Double(dy), Double(dx)) * 180.0 / Double.pi
        // SpriteKit Y is flipped vs game-world Y; map to 8 compass dirs
        let normalized = angle < 0 ? angle + 360 : angle
        let index = Int((normalized + 22.5) / 45.0) % 8
        // angle=0 → E=2, 45 → SE=3, 90 → S=4, 135 → SO=5, 180 → O=6, 225 → NO=7, 270 → N=0, 315 → NE=1
        let mapping = [2, 3, 4, 5, 6, 7, 0, 1]
        return mapping[index]
    }

    // MARK: - Patrullaje

    private func encontrarCaminoParaPatrullarAlAzar(_ i: Int, _ j: Int) -> [(i: Int, j: Int)]? {
        guard let mapa = Objeto.mapa else { return nil }
        let range = RANDOM_PATRULLA_MAX - RANDOM_PATRULLA_MIN
        let offI  = Int.random(in: 0...range) + RANDOM_PATRULLA_MIN
        let offJ  = Int.random(in: 0...range) + RANDOM_PATRULLA_MIN
        let signo = Bool.random() ? 1 : -1
        let destI = i + signo * offI
        let destJ = j + signo * offJ
        guard mapa.esPosicionCaminable(destI, destJ) else { return nil }
        return PathFinder.Instancia.encontrarCaminoMasCorto(i, j, destI, destJ)
    }

    // MARK: - Persecución y ataque

    private func actualizarEstadoPersiguiendoUnidad() {
        guard let enemigo = m_enemigo else {
            setearEstado(.OCIO)
            return
        }
        if enemigo.estaMuerto() {
            m_enemigo = nil
            setearEstado(.OCIO)
            return
        }

        let dist = calcularDistancia(enemigo.m_posEnTileFisico.x, enemigo.m_posEnTileFisico.y)

        if dist <= Double(m_alcanceDeTiro) {
            // Estamos en rango: atacar
            apuntarAUnidad(enemigo)
            setearEstado(.ATACANDO)
        } else {
            // Acercarnos
            if m_caminoASeguir == nil || m_blanco != enemigo.m_posEnTileFisico {
                m_blanco = enemigo.m_posEnTileFisico
                mover(enemigo.m_posEnTileFisico.x, enemigo.m_posEnTileFisico.y)
            } else {
                _ = moverse()
            }
        }

        let anim = primerAnimacion() + m_direccion
        m_sprite?.setearAnimacion(anim)
        m_sprite?.reproducir()
    }

    private func actualizarEstadoAtacando() {
        guard let enemigo = m_enemigo else {
            setearEstado(.OCIO)
            return
        }
        if enemigo.estaMuerto() {
            m_enemigo = nil
            setearEstado(.OCIO)
            return
        }

        m_cuenta += 1
        let anim = primerAnimacion() + m_direccion
        m_sprite?.setearAnimacion(anim)
        m_sprite?.reproducir()

        if m_cuenta >= m_intervaloEntreAtaques {
            m_cuenta = 0
            let hit = calcularDanio()
            if hit > 0 {
                enemigo.recibirDanio(hit)
                reproducirSonidoDisparo()
            }
        }

        // Volver a perseguir si se alejó
        let dist = calcularDistancia(enemigo.m_posEnTileFisico.x, enemigo.m_posEnTileFisico.y)
        if dist > Double(m_alcanceDeTiro) {
            setearEstado(.PERSIGUIENDO_UNIDAD)
        }
    }

    private func apuntarAUnidad(_ enemigo: Unidad) {
        m_enemigo = enemigo
        let di = enemigo.m_posEnTileFisico.x - m_posEnTileFisico.x
        let dj = enemigo.m_posEnTileFisico.y - m_posEnTileFisico.y
        // Convertir di/dj a dirección de sprite (8 dirs)
        let angle = atan2(Double(dj), Double(di)) * 180.0 / Double.pi
        let normalized = angle < 0 ? angle + 360 : angle
        let index = Int((normalized + 22.5) / 45.0) % 8
        let mapping = [2, 3, 4, 5, 6, 7, 0, 1]
        m_direccion = mapping[index]
    }

    private func calcularDanio() -> Int {
        let acierto = Int.random(in: 0...100)
        return acierto <= m_punteria ? m_puntosDeAtaque : 0
    }

    func recibirDanio(_ danio: Int) {
        m_salud -= danio
        if m_salud <= 0 {
            m_salud = 0
            morir()
        }
    }

    func morir() {
        Log.Instancia.debug("Me mori.")
        setearEstado(.MURIENDO)
        m_enemigo = nil
    }

    private func actualizarEstadoMuriendo() {
        let anim = primerAnimacion() + m_direccion
        m_sprite?.setearAnimacion(anim)
        m_sprite?.reproducir()
        m_sprite?.actualizar()
        m_cuenta += 1
        if m_sprite?.terminoDeAnimar() == true || m_cuenta >= CUENTA_FRAME_MUERTO {
            setearEstado(.MUERTO)
        }
    }

    private func reproducirSonidoDisparo() {
        let sfx = m_tipo == 0 ? Res.SFX_DISPARO_PATRICIO : Res.SFX_DISPARO_INGLES
        Sonido.Instancia.reproducir(sfx, 0)
    }

    // MARK: - Sanación

    private func actualizarEstadoSanando() {
        m_cuentaRecuperacion += 1
        if m_cuentaRecuperacion >= m_ticksEntreCadaRecuperacion {
            m_cuentaRecuperacion = 0
            m_salud = min(m_salud + m_puntosDeRecuperacion, m_puntosDeResistencia)
        }
        if m_salud >= m_puntosDeResistencia {
            setearEstado(.OCIO)
        }
    }

    // MARK: - Cargar desde CSV

    /// Lee los atributos de la unidad desde el archivo CSV en la ruta indexada por `id`.
    func leerUnidad(_ id: Int) {
        let paths = AdministradorDeRecursos.Instancia.pathsUnidades
        guard id >= 0, id < paths.count, let path = paths[id],
              let contenido = try? String(contentsOfFile: path, encoding: .utf8) else {
            Log.Instancia.error("No se puede leer la unidad con id=\(id)")
            return
        }

        m_tipo = id

        for linea in contenido.components(separatedBy: .newlines) {
            let partes = linea.components(separatedBy: ";")
            guard partes.count >= 2 else { continue }
            let clave = partes[0].trimmingCharacters(in: .whitespaces)
            let valor = partes[1].trimmingCharacters(in: .whitespaces)

            switch clave {
            case "Sprite":
                let spriteIdx = valor == "patricio" ? Res.SPR_PATRICIO : Res.SPR_INGLES
                m_primerSprite = 0  // animaciones comienzan en 0 dentro del sprite
                let sprs = AdministradorDeRecursos.Instancia.sprites
                if spriteIdx >= 0, spriteIdx < sprs.count, let spr = sprs[spriteIdx] {
                    m_sprite = Sprite(copia: spr)
                }
            case "Velocidad":
                let v = Int(valor) ?? 2
                m_velocidadActual     = (v, v)
                m_velocidadPorDefecto = (v, v)
            case "Puntos_Resistencia":
                let pr = Int(valor) ?? 100
                m_puntosDeResistencia = pr
                m_salud               = pr
            case "Puntos_Ataque":
                m_puntosDeAtaque = Int(valor) ?? 10
            case "Visibilidad":
                m_visibilidad = Int(valor) ?? 10
            case "Punteria":
                m_punteria = Int(valor) ?? 5
            case "Alcance_Tiro":
                m_alcanceDeTiro = Int(valor) ?? 5
            case "Intervalo_Entre_Ataques":
                m_intervaloEntreAtaques = Int(valor) ?? 30
            case "Nombre":
                m_nombre = valor
            case "Avatar":
                m_avatar = AdministradorDeRecursos.Instancia.obtenerImagen(valor)
            case "Puntos_De_Recuperacion":
                m_puntosDeRecuperacion = Int(valor) ?? 20
            case "Ticks_Entre_Recuparacion":
                m_ticksEntreCadaRecuperacion = Int(valor) ?? 50
            default:
                break
            }
        }
    }

    // MARK: - Verificar orden de objetivo

    private func chequearSiCumplioOrden() {
        guard let ord = m_ordenDeObjetivo else { return }
        if ord.id == .MOVER || ord.id == .TOMAR_OBJETO {
            if cumplioOrdenObjetivoMover() {
                m_cumplioConLaOrden = true
            }
        }
    }
}

// MARK: - Safe subscript helper
private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
