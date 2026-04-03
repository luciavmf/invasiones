// Estados/EstadoJuego.swift
// Placeholder — puerto de EstadoJuego.cs (estado de juego activo con Episodio).
// TODO: implementar cuando se porten Nivel/Episodio y Map/Mapa.

import SpriteKit

class EstadoJuego: Estado {

    override func iniciar() {
        Log.Instancia.debug("EstadoJuego: iniciar")
        // TODO: crear Episodio, iniciar HUD, cargar mapa
    }

    override func actualizar() {
        // TODO: delegar en Episodio.actualizar()
    }

    override func dibujar(_ escena: SKScene) {
        // TODO: delegar en Episodio.dibujar()
    }

    override func salir() {
        Log.Instancia.debug("EstadoJuego: salir")
        // TODO: liberar recursos del episodio
    }
}
