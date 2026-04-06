//
//  GameFrame.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of GameFrame.cs — main game coordinator.
//  The original had a blocking loop with SDL_Delay; here the loop is provided by
//  SpriteKit via GameScene.update(). GameFrame only contains state logic.
//

import SpriteKit

class GameFrame {

    // MARK: - State enum (equivalent to GameFrame.ESTADO in C#)
    enum ESTADO {
        case INVALIDO
        case FIN
        case LOGO
        case JUEGO
        case AYUDA
        case MENU_PRINCIPAL
        case INTRODUCCION_CONSECUENCIAS
        case CREDITOS
        case OPCIONES
        case SALIR
    }

    // MARK: - Declarations
    private(set) var maquinaDeEstados: MaquinaDeEstados!
    private var video: Video?

    static var FPS: Double = 0
    static var UPS: Double = 0

    // MARK: - Initializer
    init() {}

    // MARK: - Game start
    /// Called once from GameScene.didMove(to:).
    func iniciarJuego(en escena: SKScene) {
        video = Video(escena: escena)

        Mouse.Instancia.posicionarCursor(
            CGFloat(Programa.ANCHO_DE_LA_PANTALLA) / 2,
            CGFloat(Programa.ALTO_DE_LA_PANTALLA) / 2
        )
        Mouse.Instancia.ocultarCursor()

        Texto.cargar()
        AdministradorDeRecursos.Instancia.cargarPathsRecursos()
        AdministradorDeRecursos.Instancia.leerInfoSprites()
        AdministradorDeRecursos.Instancia.leerInfoAnimaciones()
        AdministradorDeRecursos.Instancia.cargarFuentes()

        Sonido.Instancia.inicializar()
        Sonido.Instancia.cargarTodosLosSonidos()

        maquinaDeEstados = MaquinaDeEstados()
        maquinaDeEstados.agregarEstado(.LOGO,           EstadoLogo(maquinaDeEstados))
        maquinaDeEstados.agregarEstado(.MENU_PRINCIPAL, EstadoMenuPpal(maquinaDeEstados))
        maquinaDeEstados.agregarEstado(.JUEGO,          EstadoJuego(maquinaDeEstados))
        maquinaDeEstados.agregarEstado(.FIN,            nil)
        maquinaDeEstados.agregarEstado(.AYUDA,          EstadoAyuda(maquinaDeEstados))
        maquinaDeEstados.agregarEstado(.OPCIONES,       EstadoOpciones(maquinaDeEstados))
        maquinaDeEstados.agregarEstado(.SALIR,          EstadoSalir(maquinaDeEstados))

        maquinaDeEstados.setearEstado(.LOGO)
        maquinaDeEstados.actualizar() // triggers iniciar() on the first state
    }

    // MARK: - Loop (called by GameScene.update every frame)
    func actualizar() {
        guard maquinaDeEstados.estadoActual != .FIN else {
            salirDeLaAplicacion()
            return
        }
        Mouse.Instancia.actualizar()
        maquinaDeEstados.actualizar()
    }

    func dibujar() {
        guard let v = video else { return }
        v.limpiar()
        maquinaDeEstados.dibujar(v)
        Mouse.Instancia.dibujarCursor(en: v)
    }

    // MARK: - Exit
    private func salirDeLaAplicacion() {
        liberarTodosLosRecursos()
        NSApplication.shared.terminate(nil)
    }

    private func liberarTodosLosRecursos() {
        maquinaDeEstados?.dispose()
        maquinaDeEstados = nil
        Log.Instancia.dispose()
    }
}
