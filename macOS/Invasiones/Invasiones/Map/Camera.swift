//
//  Camera.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Camara.cs — represents the visible portion of the map (viewport).
//

import Foundation

class Camera {

    // MARK: - Declarations
    var X: Int
    var Y: Int

    private(set) var startX: Int = 0
    private(set) var startY: Int = 0
    private(set) var width: Int = ScreenSize.SCREEN_WIDTH
    private(set) var height: Int
    private(set) var border: Int = 20
    private(set) var speed: Int = 20

    // MARK: - Initializer
    init(x: Int, y: Int, height: Int) {
        X = x
        Y = y
        self.height = height
    }

    // MARK: - Methods

    func setScreenCoords(x: Int, y: Int, w: Int, h: Int) {
        startX = max(0, x)
        startY = max(0, y)
        width = (w + x <= ScreenSize.SCREEN_WIDTH) ? w : (ScreenSize.SCREEN_WIDTH - x)
        height = (h + y <= ScreenSize.SCREEN_HEIGHT) ? h : (ScreenSize.SCREEN_HEIGHT - y)
    }
}
