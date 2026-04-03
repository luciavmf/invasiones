// Estados/EstadoJuego.swift
// Placeholder — puerto de EstadoJuego.cs (estado de juego activo con Episodio).
// TODO: implementar cuando se porten Nivel/Episodio y Map/Mapa.

import Foundation

class EstadoJuego: Estado {

    override func iniciar() {
        Log.Instancia.debug("EstadoJuego: iniciar")
    }

    override func actualizar() {}

    override func dibujar(_ g: Video) {}

    override func salir() {
        Log.Instancia.debug("EstadoJuego: salir")
    }
}
