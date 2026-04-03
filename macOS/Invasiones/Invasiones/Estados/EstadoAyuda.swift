// Estados/EstadoAyuda.swift
// Placeholder — puerto de EstadoAyuda.cs (pantallas de ayuda/tutorial).

import Foundation

class EstadoAyuda: Estado {
    override func iniciar()       { Log.Instancia.debug("EstadoAyuda: iniciar") }
    override func actualizar()    {}
    override func dibujar(_ g: Video) {}
    override func salir()         { Log.Instancia.debug("EstadoAyuda: salir") }
}
