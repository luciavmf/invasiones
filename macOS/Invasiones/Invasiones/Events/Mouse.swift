//
//  Mouse.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Mouse.cs — singleton tracking mouse position, buttons, and drag rectangle.
//  SDL replaced by NSEvent; the custom cursor is drawn as a Surface via Video.
//

import AppKit

class Mouse {

    // MARK: - Button constants (equivalent to SDL_BUTTON_*)
    static let BUTTON_LEFT = 0
    static let BUTTON_MIDDLE = 2
    static let BUTTON_RIGHT = 1

    // MARK: - Singleton
    private static var s_instance: Mouse?

    static var shared: Mouse {
        if s_instance == nil { s_instance = Mouse() }
        return s_instance!
    }

    // MARK: - Declarations
    private var m_x: CGFloat = 0
    private var m_y: CGFloat = 0
    private var m_isDragging = false
    private var m_cursorHidden = false
    private var m_finishedDragging = false
    private var m_dragStartPos: CGPoint = .zero
    private(set) var m_dragRect: CGRect = .zero

    /// Custom cursor surface (assigned from the state/level).
    private var m_cursorSurface: Surface?

    /// List of currently pressed buttons (indices BUTTON_LEFT/DER/CNT).
    private(set) var pressedButtons: [Int] = []

    // MARK: - Initializer (private — singleton)
    private init() {}

    // MARK: - Properties
    var X: CGFloat {
        get { m_x }
        set { m_x = max(0, min(newValue, CGFloat(Program.SCREEN_WIDTH))) }
    }

    var Y: CGFloat {
        get { m_y }
        set { m_y = max(0, min(newValue, CGFloat(Program.SCREEN_HEIGHT))) }
    }

    var dragRect: CGRect { m_dragRect }

    // MARK: - Button methods (called from GameScene)
    func pressButton(_ button: Int) {
        if !pressedButtons.contains(button) {
            pressedButtons.append(button)
        }
    }

    func releaseButton(_ button: Int) {
        pressedButtons.removeAll { $0 == button }
    }

    /// Updates the drag state. Call once per frame from GameFrame.update().
    func update() {
        if pressedButtons.contains(Mouse.BUTTON_LEFT) {
            m_finishedDragging = false
            if !m_isDragging {
                // New drag starts: reset rectangle and record the anchor point.
                m_isDragging = true
                m_dragStartPos = CGPoint(x: m_x, y: m_y)
                m_dragRect = .zero
            } else {
                let originX = min(m_x, m_dragStartPos.x)
                let originY = min(m_y, m_dragStartPos.y)
                let width   = abs(m_x - m_dragStartPos.x)
                let height    = abs(m_y - m_dragStartPos.y)
                m_dragRect = CGRect(x: originX, y: originY, width: width, height: height)
            }
        } else {
            // LMB released: signal that drag just finished, preserve last rectangle.
            m_finishedDragging = m_isDragging
            m_isDragging = false
            // m_dragRect is intentionally preserved so units can read it
            // on the same frame didFinishDragging() is true, matching original C# behaviour.
        }
    }

    func isDragging() -> Bool  { m_isDragging }
    func didFinishDragging() -> Bool { m_finishedDragging }

    func hideCursor() {
        m_cursorHidden = true
        NSCursor.hide()
    }

    func showCursor() {
        m_cursorHidden = false
        NSCursor.unhide()
    }

    func setCursor(_ sup: Surface?) {
        m_cursorSurface = sup
    }

    func positionCursor(_ x: CGFloat, _ y: CGFloat) {
        m_x = max(0, min(x, CGFloat(Program.SCREEN_WIDTH)))
        m_y = max(0, min(y, CGFloat(Program.SCREEN_HEIGHT)))
    }

    /// Draws the custom cursor at the current position using the Video context.
    func drawCursor(en g: Video) {
        guard !m_cursorHidden, let sup = m_cursorSurface else { return }
        g.draw(sup, Int(m_x), Int(m_y), 255, 0)
    }
}
