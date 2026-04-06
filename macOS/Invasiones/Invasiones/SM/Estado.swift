// SM/Estado.swift
// Puerto de Estado.cs — clase base abstracta de todos los estados del juego.
// En Swift se usan fatalError() para simular métodos abstractos.

import Foundation

class Estado {

    // MARK: - Declaraciones
    /// Máquina de estados padre — necesaria para cambiar de estado desde dentro.
    var maquinaDeEstados: MaquinaDeEstados

    /// Imagen de fondo del estado (cargada en iniciar(), dibujada en dibujar()).
    var m_fondo: Superficie?

    /// Botón genérico reutilizado por varios estados (e.g. "Menú", "Siguiente").
    var m_boton: Boton?

    /// Utilizado para cuentas regresivas.
    var m_cuenta: Int = 0

    // MARK: - Constructor
    init(_ sm: MaquinaDeEstados) {
        self.maquinaDeEstados = sm
    }

    // MARK: - Métodos abstractos (deben ser sobreescritos por subclases)
    func dibujar(_ g: Video) {
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
