// SM/MaquinaDeEstados.swift
// Puerto de MaquinaDeEstados.cs — máquina de estados genérica del juego.

import SpriteKit

class MaquinaDeEstados {

    // MARK: - Declaraciones
    private var m_estadoActual: Estado?
    private var m_keyEstadoActual: GameFrame.ESTADO = .INVALIDO
    private var m_estadoPrevio: Estado?
    private var m_proximoEstado: Estado?
    private var m_keyProximoEstado: GameFrame.ESTADO = .INVALIDO

    /// Diccionario con todos los estados registrados.
    private var m_todosLosEstados: [GameFrame.ESTADO: Estado?] = [:]

    // MARK: - Properties
    var estadoActual: GameFrame.ESTADO { m_keyEstadoActual }

    // MARK: - Constructor
    init() {}

    deinit {
        dispose()
    }

    func dispose() {
        m_todosLosEstados.removeAll()
    }

    // MARK: - Metodos
    /// Registra un estado en la máquina.
    func agregarEstado(_ key: GameFrame.ESTADO, _ estado: Estado?) {
        m_todosLosEstados[key] = estado
    }

    /// Encola el próximo estado para transicionar en el próximo Actualizar().
    func setearElProximoEstado(_ key: GameFrame.ESTADO) {
        guard m_todosLosEstados.keys.contains(key) else {
            Log.Instancia.error("La maquina de estados no contiene la clave \(key)")
            return
        }
        m_proximoEstado = m_todosLosEstados[key] ?? nil
        m_keyProximoEstado = key
    }

    /// Cambia al estado dado de forma inmediata (sin llamar a Salir/Iniciar).
    func setearEstado(_ key: GameFrame.ESTADO) {
        m_estadoPrevio = m_estadoActual
        m_estadoActual = m_todosLosEstados[key] ?? nil
        m_keyEstadoActual = key
    }

    /// Actualiza la máquina: gestiona la transición pendiente y delega en el estado actual.
    func actualizar() {
        if let proximo = m_proximoEstado {
            m_estadoPrevio = m_estadoActual
            m_estadoActual = proximo
            m_keyEstadoActual = m_keyProximoEstado

            m_proximoEstado = nil
            m_keyProximoEstado = .INVALIDO

            m_estadoPrevio?.salir()
            m_estadoActual?.iniciar()
        }

        m_estadoActual?.actualizar()
    }

    /// Dibuja el estado actual.
    func dibujar(_ escena: SKScene) {
        m_estadoActual?.dibujar(escena)
    }
}
