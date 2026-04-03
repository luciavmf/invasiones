// SM/Estado.swift
// Puerto de Estado.cs — clase base abstracta de todos los estados del juego.
// En Swift se usan fatalError() para simular métodos abstractos.

import SpriteKit

class Estado {

    // MARK: - Declaraciones
    /// Máquina de estados padre — necesaria para cambiar de estado desde dentro.
    var maquinaDeEstados: MaquinaDeEstados

    /// Nodo raíz que el estado agrega a la escena para dibujar su contenido.
    var m_fondo: SKSpriteNode?

    /// Botón de propósito general (se tipará correctamente cuando se porte GUI/Boton).
    // var m_boton: Boton?  // TODO: descommentar al portar GUI/Boton

    /// Utilizado para cuentas regresivas.
    var m_cuenta: Int = 0

    // MARK: - Constructor
    init(_ sm: MaquinaDeEstados) {
        self.maquinaDeEstados = sm
    }

    // MARK: - Métodos abstractos (deben ser sobreescritos por subclases)
    func dibujar(_ escena: SKScene) {
        fatalError("\(type(of: self)).dibujar(_:) must be overridden")
    }

    func actualizar() {
        fatalError("\(type(of: self)).actualizar() must be overridden")
    }

    func iniciar() {
        fatalError("\(type(of: self)).iniciar() must be overridden")
    }

    func salir() {
        fatalError("\(type(of: self)).salir() must be overridden")
    }
}
