// Estados/EstadoLogo.swift
// Placeholder — puerto de EstadoLogo.cs (pantalla de logo/splash).
// TODO: implementar lógica de splash cuando se porte Dibujo/Superficie.

import SpriteKit

class EstadoLogo: Estado {

    override func iniciar() {
        Log.Instancia.debug("EstadoLogo: iniciar")
        // TODO: cargar imagen de logo y reproducir por N frames
    }

    override func actualizar() {
        // TODO: cuenta regresiva; por ahora va directo al menú principal
        maquinaDeEstados.setearElProximoEstado(.MENU_PRINCIPAL)
    }

    override func dibujar(_ escena: SKScene) {
        // TODO: dibujar logo
    }

    override func salir() {
        Log.Instancia.debug("EstadoLogo: salir")
    }
}
