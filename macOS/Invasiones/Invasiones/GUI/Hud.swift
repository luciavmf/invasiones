// GUI/Hud.swift
// Puerto de Hud.cs — cabecera de información (HUD) del juego.

import Foundation

class Hud {

    // MARK: - Constantes de posición
    static let AVATAR_X         = 61
    static let AVATAR_Y         = 11
    static let AVATAR_NOMBRE_X  = 126
    static let AVATAR_NOMBRE_ANCHO = 82
    static let AVATAR_NOMBRE_Y  = 6
    static let ATRIBUTOS_INICIO_X_1 = 141
    static let ATRIBUTOS_INICIO_X_2 = 215
    static let ATRIBUTOS_INICIO_X_3 = 338
    static let ATRIBUTOS_INICIO_Y   = 25
    static let ATRIBUTOS_CANT_Y     = 35
    static let ATRIBUTOS_CANT_INGL_X = 705
    static let ATRIBUTOS_CANT_ARG_X  = 570

    // MARK: - Declaraciones
    private var m_imagen:            Superficie?
    private var m_unidadAMostrar:    Unidad?
    private var m_cantidadEnemigos:  Int = 0
    private var m_cantidadArgentinos:Int = 0
    private var m_y:                 Int = 0
    private let m_espaciadoLineas    = 12
    private var m_tipVentana:        Tips

    // MARK: - Properties
    var unidadSeleccionada: Unidad? {
        set { m_unidadAMostrar = newValue }
        get { m_unidadAMostrar }
    }

    var cantidadArgentinos: Int {
        get { m_cantidadArgentinos }
        set { m_cantidadArgentinos = newValue }
    }

    var cantidadEnemigos: Int {
        get { m_cantidadEnemigos }
        set { m_cantidadEnemigos = newValue }
    }

    var alto: Int { m_imagen?.alto ?? 0 }

    // MARK: - Constructor
    init() {
        m_imagen     = AdministradorDeRecursos.Instancia.obtenerImagen(Res.IMG_HUD)
        m_y          = Video.Alto - (m_imagen?.alto ?? 0)
        m_tipVentana = Tips()
        m_tipVentana.setearPosicion(
            ((Video.Ancho - m_tipVentana.ancho) / 2) + 175,
            m_y - m_tipVentana.alto - 75,
            0)
    }

    // MARK: - Actualizar
    func actualizar() {
        if let u = m_unidadAMostrar, u.estaMuerto() {
            m_unidadAMostrar = nil
        }
        m_tipVentana.actualizar()
    }

    // MARK: - Dibujar
    func dibujar(_ g: Video) {
        if let img = m_imagen {
            // V_FONDO = dibuja en la parte inferior
            g.dibujar(img, 0, m_y, 0)
        }
        m_tipVentana.dibujar(g)

        g.setearFuente(AdministradorDeRecursos.Instancia.fuentes[Definiciones.FNT.SANS12.rawValue],
                       Definiciones.COLOR_NEGRO)
        g.escribir("\(m_cantidadEnemigos)",   Hud.ATRIBUTOS_CANT_INGL_X, m_y + Hud.ATRIBUTOS_CANT_Y, 0)
        g.escribir("\(m_cantidadArgentinos)", Hud.ATRIBUTOS_CANT_ARG_X,  m_y + Hud.ATRIBUTOS_CANT_Y, 0)

        g.setearFuente(AdministradorDeRecursos.Instancia.fuentes[Definiciones.FNT.SANS12.rawValue],
                       Definiciones.COLOR_BLANCO)

        guard let uni = m_unidadAMostrar else { return }

        if let av = uni.avatar {
            g.dibujar(av, Hud.AVATAR_X, m_y + Hud.AVATAR_Y, 0)
        }
        g.escribir(uni.nombre, Hud.AVATAR_NOMBRE_X, m_y + Hud.AVATAR_NOMBRE_Y, 0)

        g.setearColor(Definiciones.COLOR_NEGRO)

        let s = Texto.Strings
        g.escribir("\(s[safe: Res.STR_ALCANCE] ?? ""):\(uni.alcance)",
                   Hud.ATRIBUTOS_INICIO_X_1, m_y + Hud.ATRIBUTOS_INICIO_Y, 0)
        g.escribir("\(s[safe: Res.STR_PUNTERIA] ?? ""):\(uni.punteria)",
                   Hud.ATRIBUTOS_INICIO_X_1, m_y + Hud.ATRIBUTOS_INICIO_Y + m_espaciadoLineas, 0)
        g.escribir("\(s[safe: Res.STR_PUNTOS_DE_ATAQUE] ?? ""):\(uni.puntosDeAtaque)",
                   Hud.ATRIBUTOS_INICIO_X_2, m_y + Hud.ATRIBUTOS_INICIO_Y, 0)
        g.escribir("\(s[safe: Res.STR_PUNTOS_DE_RESISTENCIA] ?? ""):\(uni.salud)/\(uni.puntosDeResistencia)",
                   Hud.ATRIBUTOS_INICIO_X_2, m_y + Hud.ATRIBUTOS_INICIO_Y + m_espaciadoLineas, 0)
        g.escribir("\(s[safe: Res.STR_VELOCIDAD] ?? ""):\(uni.velocidadPorDefecto)",
                   Hud.ATRIBUTOS_INICIO_X_3, m_y + Hud.ATRIBUTOS_INICIO_Y, 0)
        g.escribir("\(s[safe: Res.STR_VISIBILIDAD] ?? ""):\(uni.visibilidad)",
                   Hud.ATRIBUTOS_INICIO_X_3, m_y + Hud.ATRIBUTOS_INICIO_Y + m_espaciadoLineas, 0)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
