// Recursos/Definiciones.swift
// Puerto de Definiciones.cs — constantes globales del juego.

import Foundation

enum Definiciones {

    // MARK: - Cheats
    static let CHEATS_HABILITADOS = true

    // MARK: - Colores (RGB hex)
    static let COLOR_GRIS        = 0xC8C8C8
    static let COLOR_ROJO        = 0xFF0000
    static let COLOR_NEGRO       = 0x000000
    static let COLOR_BLANCO      = 0xFFFFFF
    static let COLOR_VERDE       = 0x00FF00
    static let COLOR_AZUL        = 0x0000FF
    static let COLOR_CELESTE     = 0x00FFFF
    static let COLOR_MAGENTA     = 0xFF00FF
    static let COLOR_TRANSPARENTE = COLOR_MAGENTA

    // MARK: - Layout
    static let OFFSET_OBJETIVOS   = 7
    static let ANCHO_OBJETIVOS    = 410
    static let ALTO_OBJETIVOS     = 22
    static let ESPACIO_ENTRE_LINEAS = 5

    static let COLOR_LOADING   = COLOR_AZUL
    static let COLOR_TITULO    = COLOR_BLANCO
    static let COLOR_OBJETIVOS = COLOR_NEGRO

    static let CUENTA_MOSTRAR_OBJETIVO_INICIO = 50
    static let BOTON_OBJETIVOS_Y              = 510
    static let MENU_PRINCIPAL_Y_OFFSET        = 50
    static let BORDE_OBJETIVOS                = 100
    static let CARGANDO_Y                     = 200
    static let TEXTO_AYUDA_Y                  = 200
    static let TEXTO_AYUDA_ITEM_Y             = 150

    /// Posición Y de todos los títulos.
    static let TITULO_Y          = 30
    static let JUEGO_PAUSADO_Y   = -200

    // MARK: - GUI
    static let GUI_COLOR_MENUS    = COLOR_NEGRO
    static let GUI_COLOR_SELECCION = COLOR_ROJO
    static let GUI_COLOR_TEXTO    = COLOR_BLANCO
    static let GUI_ALPHA          = 128

    static let ALPHA_OBJETIVOS    = GUI_ALPHA
    static let CONFIRMACION_ALPHA = 128
    static let CONFIRMACION_ANCHO = 350
    static let CONFIRMACION_ALTO  = 150

    static let TIPS_ALPHA = 100
    static let TIPS_ANCHO = 450
    static let TIPS_ALTO  = 100

    static let PRESIONE_PARA_CONTINUAR_Y = 200
    static let PAGINAS_POR_INTRO         = 3
    static let TOTAL_TICKS_HASTA_OBJETIVO = 50

    // MARK: - Fuentes
    enum FNT: Int {
        case SANS12 = 0
        case SANS14
        case SANS18
        case SANS20
        case SANS24
        case SANS28
        case LBLACK12
        case LBLACK14
        case LBLACK18
        case LBLACK20
        case LBLACK28
        case TOTAL
    }

    static let FUENTE_TITULO_OBJETIVOS       = FNT.LBLACK28.rawValue
    static let FUENTE_TITULO                 = FNT.LBLACK28.rawValue
    static let FUENTE_TITULO_AYUDA           = FNT.SANS24.rawValue
    static let FUENTE_AYUDA                  = FNT.SANS18.rawValue
    static let FUENTE_MENU                   = FNT.SANS20.rawValue
    static let FUENTE_BOTON                  = FNT.SANS14.rawValue
    static let FUENTE_RECORDATORIO_OBJETIVOS = FNT.SANS14.rawValue
    static let FUENTE_OBJETIVOS              = FNT.SANS20.rawValue
    static let FUENTE_GANO                   = FNT.LBLACK28.rawValue

    static let COLOR_FUENTE_OBJETIVOS = COLOR_BLANCO
    static let COLOR_TEXTO_GANO       = COLOR_BLANCO

    // MARK: - Direcciones de sprite (8 direcciones)
    enum DIRECCION: Int {
        case N = 0, NE, E, SE, S, SO, O, NO
        static let CANTIDAD_DIRECCIONES = 8
    }
}
