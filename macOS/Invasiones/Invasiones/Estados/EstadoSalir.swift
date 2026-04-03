// Estados/EstadoSalir.swift
// Placeholder — puerto de EstadoSalir.cs (confirmación de salida).

import Foundation

class EstadoSalir: Estado {
    override func iniciar() {
        Log.Instancia.debug("EstadoSalir: iniciar")
        // Por ahora sale directamente sin confirmación.
        maquinaDeEstados.setearElProximoEstado(.FIN)
    }
    override func actualizar()        {}
    override func dibujar(_ g: Video) {}
    override func salir()             { Log.Instancia.debug("EstadoSalir: salir") }
}
