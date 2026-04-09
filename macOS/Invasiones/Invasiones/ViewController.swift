//
//  ViewController.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 03.04.26.
//

import Cocoa
import SpriteKit

class ViewController: NSViewController {

    private var skView: SKView!

    override func loadView() {
        skView = SKView(frame: NSRect(x: 0, y: 0, width: ScreenSize.width, height: ScreenSize.height))
        view = skView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let scene = GameScene(size: CGSize(width: ScreenSize.width, height: ScreenSize.height))
        scene.anchorPoint = CGPoint(x: 0, y: 0)
        scene.scaleMode = .aspectFit
        skView.presentScene(scene)
        skView.ignoresSiblingOrder = true
        // Black background for letterbox bars when window aspect ratio doesn't match 4:3.
        skView.wantsLayer = true
        skView.layer?.backgroundColor = NSColor.black.cgColor

#if DEBUG
        skView.showsFPS = true
        skView.showsNodeCount = true
#endif
    }
}
