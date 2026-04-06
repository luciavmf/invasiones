// Eventos/Teclado.swift
// Puerto de Teclado.cs — singleton que rastrea teclas presionadas.
// SDL keycodes reemplazados por los keyCode de NSEvent (Carbon virtual key codes).

import AppKit

class Teclado {

    // MARK: - Constantes de teclas (Carbon virtual key codes en macOS)
    static let INTERVALO_ENTRE_REPETICIONES = 15

    static let TECLA_ARR      = 126   // kVK_UpArrow
    static let TECLA_ABJ      = 125   // kVK_DownArrow
    static let TECLA_IZQ      = 123   // kVK_LeftArrow
    static let TECLA_DER      = 124   // kVK_RightArrow

    static let TECLA_A = 0;  static let TECLA_B = 11; static let TECLA_C = 8
    static let TECLA_D = 2;  static let TECLA_E = 14; static let TECLA_F = 3
    static let TECLA_G = 5;  static let TECLA_H = 4;  static let TECLA_I = 34
    static let TECLA_J = 38; static let TECLA_K = 40; static let TECLA_L = 37
    static let TECLA_M = 46; static let TECLA_N = 45; static let TECLA_O = 31
    static let TECLA_P = 35; static let TECLA_Q = 12; static let TECLA_R = 15
    static let TECLA_S = 1;  static let TECLA_T = 17; static let TECLA_U = 32
    static let TECLA_V = 9;  static let TECLA_W = 13; static let TECLA_X = 7
    static let TECLA_Y = 16; static let TECLA_Z = 6

    static let TECLA_RSHIFT    = 60   // kVK_RightShift
    static let TECLA_LSHIFT    = 56   // kVK_Shift
    static let TECLA_MAYUSCULA = 57   // kVK_CapsLock
    static let TECLA_BACKSPACE = 51   // kVK_Delete
    static let TECLA_ENTER     = 36   // kVK_Return
    static let TECLA_ESC       = 53   // kVK_Escape

    // MARK: - Singleton
    private static var s_instancia: Teclado?

    static var Instancia: Teclado {
        if s_instancia == nil { s_instancia = Teclado() }
        return s_instancia!
    }

    // MARK: - Declaraciones
    /// Teclas actualmente presionadas (keyCode de NSEvent).
    private(set) var TeclasApretadas: [Int] = []

    // MARK: - Constructor (privado — singleton)
    private init() {}

    // MARK: - Metodos (llamados desde GameScene)
    func presionarTecla(_ keyCode: Int) {
        if !TeclasApretadas.contains(keyCode) {
            TeclasApretadas.append(keyCode)
        }
    }

    func soltarTecla(_ keyCode: Int) {
        TeclasApretadas.removeAll { $0 == keyCode }
    }

    func limpiarTeclas() {
        TeclasApretadas.removeAll()
    }
}
