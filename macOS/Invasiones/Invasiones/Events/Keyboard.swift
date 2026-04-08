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

    // MARK: - Key codes (Carbon virtual key codes on macOS)
    enum Key: Int {
        case a = 0,  s = 1,  d = 2,  f = 3,  h = 4,  g = 5,  z = 6,  x = 7
        case c = 8,  v = 9,  b = 11, q = 12, w = 13, e = 14, r = 15, y = 16
        case t = 17, u = 32, i = 34, o = 31, p = 35, l = 37, j = 38, k = 40
        case n = 45, m = 46
        case enter = 36
        case backspace = 51
        case escape = 53
        case lShift = 56, capsLock = 57, rShift = 60
        case left = 123, right = 124, down = 125, up = 126
    }

    // MARK: - Singleton
    static let shared = Keyboard()

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
