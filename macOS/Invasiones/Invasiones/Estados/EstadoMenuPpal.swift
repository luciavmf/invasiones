// Estados/EstadoMenuPpal.swift
// Placeholder — puerto de EstadoMenuPpal.cs (menú principal).
// TODO: implementar menú completo cuando se porten GUI/Menu y Dibujo/Superficie.

import SpriteKit

class EstadoMenuPpal: Estado {

    override func iniciar() {
        Log.Instancia.debug("EstadoMenuPpal: iniciar")
        // TODO: construir opciones del menú (Nuevo Juego, Opciones, Ayuda, Salir)
    }

    override func actualizar() {
        // TODO: procesar selección de menú con Mouse/Teclado
    }

    override func dibujar(_ escena: SKScene) {
        // TODO: dibujar fondo y opciones de menú
    }

    override func salir() {
        Log.Instancia.debug("EstadoMenuPpal: salir")
    }
}
