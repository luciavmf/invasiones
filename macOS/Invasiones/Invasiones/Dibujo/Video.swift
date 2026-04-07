//
//  Video.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 06.04.26.
//
//  Port of Video.cs — screen drawing context.
//  In SDL it was an SDL_Surface with blit primitives. In SpriteKit we maintain a
//  canvas node, adding children each frame and clearing at the start of the next.
//

import SpriteKit

/// The drawing surface that represents the screen.
/// Wraps SpriteKit and exposes an SDL-compatible draw API to the rest of the game.
/// All objects are added to a canvas node each frame and cleared at the start of the next.
class Video {

    // MARK: - Screen constants (equivalent to the static fields of Video in C#)
    static let width: Int = Program.SCREEN_WIDTH
    static let height: Int = Program.SCREEN_HEIGHT

    // MARK: - Nodo canvas
    private let canvasNode: SKNode

    // MARK: - Drawing state
    private var currentColor: SKColor = .black
    private var currentFont: GameFont?
    private var fontColor: SKColor = .white
    private var zPos: CGFloat = 0

    // Clip rect in C# coordinates (top-left origin). Only the state is persisted;
    // actual visual clipping is handled by the map renderer itself.
    private var clipX: Int = 0
    private var clipY: Int = 0
    private var clipW: Int = Program.SCREEN_WIDTH
    private var clipH: Int = Program.SCREEN_HEIGHT

    // MARK: - Initializer
    init(escena: SKScene) {
        canvasNode = SKNode()
        escena.addChild(canvasNode)
    }

    // MARK: - Frame management

    /// Removes all nodes from the previous frame and resets the Z order.
    func clear() {
        canvasNode.removeAllChildren()
        zPos = 0
    }

    // MARK: - Draw surfaces

    /// Draws a surface (or its active clip) at C# coordinates (x, y) with an anchor.
    func draw(_ surface: Surface?, _ x: Int, _ y: Int, _ anchor: Int) {
        let alpha = Int((surface?.currentAlpha ?? 1.0) * 255.0)
        draw(surface, x, y, alpha, anchor)
    }

    /// Draws a surface with an explicit transparency value (alpha 0-255).
    func draw(_ surface: Surface?, _ x: Int, _ y: Int, _ alpha: Int, _ anchor: Int) {
        guard let sup = surface,
              let tex = sup.currentTexture ?? sup.texture else { return }

        var px = x, py = y
        let fw = Int(tex.size().width)
        let fh = Int(tex.size().height)

        if (anchor & Surface.centerHorizontal) != 0 { px += Video.width / 2 - fw / 2 }
        if (anchor & Surface.centerVertical) != 0 { py += Video.height  / 2 - fh / 2 }

        let node = SKSpriteNode(texture: tex)
        node.anchorPoint = CGPoint(x: 0, y: 1)          // top-left anchor
        node.position    = CGPoint(x: px, y: Video.height - py)
        node.alpha       = CGFloat(max(0, min(alpha, 255))) / 255.0
        node.zPosition   = zPos; zPos += 1
        canvasNode.addChild(node)
    }

    /// Draws a sub-region of a surface at a destination position (tile blit).
    func draw(_ superficie: Surface?, _ srcX: Int, _ srcY: Int, _ srcW: Int, _ srcH: Int,
                 _ destX: Int, _ destY: Int) {
        guard let sup = superficie, let tex = sup.texture else { return }
        let texW = tex.size().width
        let texH = tex.size().height
        guard texW > 0, texH > 0, srcW > 0, srcH > 0 else { return }

        let nx = CGFloat(srcX) / texW
        let ny = 1.0 - CGFloat(srcY + srcH) / texH
        let nw = CGFloat(srcW) / texW
        let nh = CGFloat(srcH) / texH

        let subTex = SKTexture(rect: CGRect(x: nx, y: ny, width: nw, height: nh), in: tex)
        subTex.filteringMode = .nearest

        let node = SKSpriteNode(texture: subTex)
        node.anchorPoint = CGPoint(x: 0, y: 1)
        node.position    = CGPoint(x: destX, y: Video.height - destY)
        node.alpha       = sup.currentAlpha
        node.zPosition   = zPos; zPos += 1
        canvasNode.addChild(node)
    }

    // MARK: - Clip

    func getClip() -> (x: Int, y: Int, w: Int, h: Int) { (clipX, clipY, clipW, clipH) }

    func setClip(x: Int, y: Int, w: Int, h: Int) {
        clipX = x; clipY = y; clipW = w; clipH = h
    }

    // MARK: - Write text

    /// Writes the string identified by its ID (index in GameText.Strings) with an anchor.
    func write(_ stringId: Int, _ x: Int, _ y: Int, _ anchor: Int) {
        let strings = GameText.Strings
        guard stringId >= 0, stringId < strings.count else { return }
        writeText(strings[stringId], x, y, anchor)
    }

    /// Writes a string literal (for debug output and dynamic text).
    func write(_ text: String, _ x: Int, _ y: Int, _ anchor: Int) {
        writeText(text, x, y, anchor)
    }

    private func writeText(_ text: String, _ x: Int, _ y: Int, _ anchor: Int) {
        var px = x, py = y
        if (anchor & Surface.centerHorizontal) != 0 { px += Video.width / 2 }
        if (anchor & Surface.centerVertical) != 0 { py += Video.height  / 2 }

        let label = SKLabelNode()
        let nsFont: NSFont
        if let font = currentFont?.nsFont {
            label.fontName = font.fontName
            label.fontSize = font.pointSize
            nsFont = font
        } else {
            label.fontSize = 14
            nsFont = NSFont.systemFont(ofSize: 14)
        }
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: nsFont,
            .foregroundColor: fontColor,
            .paragraphStyle: paraStyle
        ]
        label.attributedText = NSAttributedString(string: text, attributes: attrs)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = (anchor & Surface.centerVertical) != 0 ? .center : .top
        label.numberOfLines = 0      // allows line breaks with \n
        label.preferredMaxLayoutWidth = CGFloat(Video.width - 80)  // enables word-wrap and avoids clipping
        label.position = CGPoint(x: px, y: Video.height - py)
        label.zPosition = zPos; zPos += 1
        canvasNode.addChild(label)
    }

    // MARK: - Fill primitives

    /// Fills a rectangle with the current colour, optional alpha and anchor.
    func fillRect(_ x: Int, _ y: Int, _ w: Int, _ h: Int,
                  _ alpha: Int = 255, _ anchor: Int = 0) {
        var px = x, py = y
        if (anchor & Surface.centerHorizontal) != 0 { px += Video.width / 2 - w / 2 }
        if (anchor & Surface.centerVertical) != 0 { py += Video.height  / 2 - h / 2 }
        let node = SKSpriteNode(color: currentColor,
                                size: CGSize(width: w, height: h))
        node.anchorPoint = CGPoint(x: 0, y: 1)
        node.position    = CGPoint(x: px, y: Video.height - py)
        node.alpha       = CGFloat(max(0, min(alpha, 255))) / 255.0
        node.zPosition   = zPos; zPos += 1
        canvasNode.addChild(node)
    }

    /// Fills the entire screen with a solid colour (overload without coordinates).
    func fillRect(_ color: Int) {
        setColor(color)
        fillRect(0, 0, Video.width, Video.height)
    }

    // MARK: - Drawing state

    func setColor(_ color: Int) {
        currentColor = skColor(color)
    }

    func setFont(_ font: GameFont?, _ color: Int) {
        currentFont = font
        fontColor = skColor(color)
    }

    /// Draws the outline of a rectangle (no fill) with the current colour.
    func drawRect(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ anchor: Int) {
        var px = x, py = y
        if (anchor & Surface.centerHorizontal) != 0 { px += Video.width / 2 - w / 2 }
        if (anchor & Surface.centerVertical) != 0 { py += Video.height  / 2 - h / 2 }

        let shape = SKShapeNode(rect: CGRect(x: px, y: Video.height - py - h, width: w, height: h))
        shape.strokeColor = currentColor
        shape.fillColor   = .clear
        shape.lineWidth   = 1
        shape.zPosition   = zPos; zPos += 1
        canvasNode.addChild(shape)
    }

    /// No-op: SpriteKit manages double-buffering automatically.
    func refresh() {}

    // MARK: - Helpers

    private func skColor(_ rgb: Int) -> SKColor {
        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >>  8) & 0xFF) / 255.0
        let b = CGFloat( rgb        & 0xFF) / 255.0
        return SKColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}
