// Estados/EstadoOpciones.swift
// Placeholder — puerto de EstadoOpciones.cs (menú de opciones).

import Foundation

class EstadoOpciones: Estado {
    override func iniciar()           { Log.Instancia.debug("EstadoOpciones: iniciar") }
    override func actualizar()        {}
    override func dibujar(_ g: Video) {}
    override func salir()             { Log.Instancia.debug("EstadoOpciones: salir") }
}
