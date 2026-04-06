// GameFrame.swift
// Puerto de GameFrame.cs — coordinador principal del juego.
// En el original contenía el loop bloqueante con SDL_Delay; aquí el loop lo provee
// SpriteKit a través de GameScene.update(). GameFrame sólo contiene lógica de estado.

import SpriteKit

class GameFrame {

    // MARK: - Enum de estados (equivalente a GameFrame.ESTADO en C#)
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

    // MARK: - Declaraciones
    private(set) var maquinaDeEstados: MaquinaDeEstados!
    private var video: Video?

    static var FPS: Double = 0
    static var UPS: Double = 0

    // MARK: - Constructor
    init() {}

    // MARK: - Inicio del juego
    /// Llamado una vez desde GameScene.didMove(to:).
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

        maquinaDeEstados = MaquinaDeEstados()
        maquinaDeEstados.agregarEstado(.LOGO,           EstadoLogo(maquinaDeEstados))
        maquinaDeEstados.agregarEstado(.MENU_PRINCIPAL, EstadoMenuPpal(maquinaDeEstados))
        maquinaDeEstados.agregarEstado(.JUEGO,          EstadoJuego(maquinaDeEstados))
        maquinaDeEstados.agregarEstado(.FIN,            nil)
        maquinaDeEstados.agregarEstado(.AYUDA,          EstadoAyuda(maquinaDeEstados))
        maquinaDeEstados.agregarEstado(.OPCIONES,       EstadoOpciones(maquinaDeEstados))
        maquinaDeEstados.agregarEstado(.SALIR,          EstadoSalir(maquinaDeEstados))

        maquinaDeEstados.setearEstado(.LOGO)
        maquinaDeEstados.actualizar() // dispara iniciar() del primer estado
    }

    // MARK: - Loop (llamado por GameScene.update cada frame)
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

    // MARK: - Salida
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
