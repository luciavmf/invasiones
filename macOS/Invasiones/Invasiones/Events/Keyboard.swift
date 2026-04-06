//
//  Keyboard.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Teclado.cs — singleton tracking pressed keys.
//  SDL keycodes replaced by NSEvent keyCode (Carbon virtual key codes).
//

import AppKit

class Keyboard {

    // MARK: - Key constants (Carbon virtual key codes on macOS)
    static let KEY_REPEAT_INTERVAL = 15

    static let KEY_UP      = 126   // kVK_UpArrow
    static let KEY_DOWN      = 125   // kVK_DownArrow
    static let KEY_LEFT      = 123   // kVK_LeftArrow
    static let KEY_RIGHT      = 124   // kVK_RightArrow

    static let KEY_A = 0;  static let KEY_B = 11; static let KEY_C = 8
    static let KEY_D = 2;  static let KEY_E = 14; static let KEY_F = 3
    static let KEY_G = 5;  static let KEY_H = 4;  static let KEY_I = 34
    static let KEY_J = 38; static let KEY_K = 40; static let KEY_L = 37
    static let KEY_M = 46; static let KEY_N = 45; static let KEY_O = 31
    static let KEY_P = 35; static let KEY_Q = 12; static let KEY_R = 15
    static let KEY_S = 1;  static let KEY_T = 17; static let KEY_U = 32
    static let KEY_V = 9;  static let KEY_W = 13; static let KEY_X = 7
    static let KEY_Y = 16; static let KEY_Z = 6

    static let KEY_RSHIFT    = 60   // kVK_RightShift
    static let KEY_LSHIFT    = 56   // kVK_Shift
    static let KEY_CAPSLOCK = 57   // kVK_CapsLock
    static let KEY_BACKSPACE = 51   // kVK_Delete
    static let KEY_ENTER     = 36   // kVK_Return
    static let KEY_ESC       = 53   // kVK_Escape

    // MARK: - Singleton
    private static var instance: Keyboard?

    static var shared: Keyboard {
        if instance == nil { instance = Keyboard() }
        return instance!
    }

    // MARK: - Declarations
    /// Teclas actualmente presionadas (keyCode de NSEvent).
    private(set) var pressedKeys: [Int] = []

    // MARK: - Initializer (privado — singleton)
    private init() {}

    // MARK: - Methods (llamados desde GameScene)
    func pressKey(_ keyCode: Int) {
        if !pressedKeys.contains(keyCode) {
            pressedKeys.append(keyCode)
        }
    }

    func releaseKey(_ keyCode: Int) {
        pressedKeys.removeAll { $0 == keyCode }
    }

    func clearKeys() {
        pressedKeys.removeAll()
    }
}
