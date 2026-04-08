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
    enum Constants {
        static let leftButton = 0
        static let middleButton = 2
        static let rightButton = 1
    }

    // MARK: - Singleton
    static let shared = Mouse()

    // MARK: - Declarations
    private var _x: CGFloat = 0
    private var _y: CGFloat = 0
    private var dragging = false
    private var cursorHidden = false
    private var finishedDragging = false
    private var dragStartPos: CGPoint = .zero
    private(set) var dragRectStore: CGRect = .zero

    /// Custom cursor surface (assigned from the state/level).
    private var cursorSurface: Surface?

    /// List of currently pressed buttons (indices BUTTON_LEFT/DER/CNT).
    private(set) var pressedButtons: [Int] = []

    // MARK: - Initializer (private — singleton)
    private init() {}

    // MARK: - Properties
    var x: CGFloat {
        get { _x }
        set { _x = max(0, min(newValue, CGFloat(ScreenSize.width))) }
    }

    var y: CGFloat {
        get { _y }
        set { _y = max(0, min(newValue, CGFloat(ScreenSize.height))) }
    }

    var dragRect: CGRect { dragRectStore }

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
        if pressedButtons.contains(Constants.leftButton) {
            finishedDragging = false
            if !dragging {
                // New drag starts: reset rectangle and record the anchor point.
                dragging = true
                dragStartPos = CGPoint(x: _x, y: _y)
                dragRectStore = .zero
            } else {
                let originX = min(_x, dragStartPos.x)
                let originY = min(_y, dragStartPos.y)
                let width = abs(_x - dragStartPos.x)
                let height = abs(_y - dragStartPos.y)
                dragRectStore = CGRect(x: originX, y: originY, width: width, height: height)
            }
        } else {
            // LMB released: signal that drag just finished, preserve last rectangle.
            finishedDragging = dragging
            dragging = false
            // dragRectStore is intentionally preserved so units can read it
            // on the same frame didFinishDragging() is true, matching original C# behaviour.
        }
    }

    func isDragging() -> Bool  { dragging }
    func didFinishDragging() -> Bool { finishedDragging }

    func hideCursor() {
        cursorHidden = true
        NSCursor.hide()
    }

    func showCursor() {
        cursorHidden = false
        NSCursor.unhide()
    }

    func setCursor(_ sup: Surface?) {
        cursorSurface = sup
    }

    func positionCursor(x: CGFloat, y: CGFloat) {
        _x = max(0, min(x, CGFloat(ScreenSize.width)))
        _y = max(0, min(y, CGFloat(ScreenSize.height)))
    }

    /// Draws the custom cursor at the current position using the Video context.
    func drawCursor(_ video: Video) {
        guard !cursorHidden, let sup = cursorSurface else { return }
        video.draw(sup, Int(_x), Int(_y), 255, 0)
    }
}
