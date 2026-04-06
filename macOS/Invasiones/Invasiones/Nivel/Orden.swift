// Nivel/Orden.swift
// Puerto de Orden.cs — representa una orden que una unidad o grupo debe cumplir.

import Foundation

class Orden {

    enum TIPO: Int {
        case INVALIDA = -1
        case TOMAR_OBJETO = 0
        case MOVER
        case ATACAR
        case PATRULLAR
        case SANAR
        case TRIGGER
        case MATAR
    }

    // MARK: - Declaraciones
    private(set) var id:        TIPO
    private(set) var punto:     (x: Int, y: Int)
    private(set) var imagen:    Superficie?
    private(set) var animacion: AnimObjeto?
    private(set) var ancho:     Int = 0

    // MARK: - Constructores

    init(_ tipo: TIPO, _ x: Int, _ y: Int) {
        id    = tipo
        punto = (x, y)
    }

    init(_ tipo: TIPO, _ x: Int, _ y: Int, _ anchoParam: Int) {
        id    = tipo
        punto = (x, y)
        ancho = anchoParam
    }

    init(_ tipo: TIPO, _ x: Int, _ y: Int, _ path: String) {
        id    = tipo
        punto = (x, y)
        if let p = Utilidades.obtenerPath(path) {
            imagen = AdministradorDeRecursos.Instancia.obtenerImagen(p)
        }
        if imagen == nil {
            Log.Instancia.debug("No se puede obtener la imagen que esta en el nivel: \(path)")
        }
    }

    init(_ tipo: TIPO, _ x: Int, _ y: Int, _ anim: AnimObjeto?) {
        id        = tipo
        punto     = (x, y)
        animacion = anim
    }
}
