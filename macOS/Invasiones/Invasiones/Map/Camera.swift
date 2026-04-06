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

    private var m_startX: Int = 0
    private var m_startY: Int = 0
    private var m_width:   Int = Program.SCREEN_WIDTH
    private var m_height:    Int
    private var m_border:   Int = 20
    private var m_speed: Int = 20

    // MARK: - Properties
    var startX:   Int { m_startX }
    var startY:   Int { m_startY }
    var width:     Int { m_width }
    var height:      Int { m_height }
    var border:     Int { m_border }
    var speed: Int { m_speed }

    // MARK: - Initializer
    init(x: Int, y: Int, height: Int) {
        X = x
        Y = y
        m_height = height
    }

    // MARK: - Methods

    func setScreenCoords(_ x: Int, _ y: Int, _ w: Int, _ h: Int) {
        m_startX = max(0, x)
        m_startY = max(0, y)
        m_width   = (w + x <= Program.SCREEN_WIDTH) ? w : (Program.SCREEN_WIDTH - x)
        m_height    = (h + y <= Program.SCREEN_HEIGHT)  ? h : (Program.SCREEN_HEIGHT  - y)
    }
}
