//
//  ViewController.swift
//  Invasiones
//
//  Created by Lucia Medina Fretes on 03.04.26.
//

import Cocoa
import SpriteKit
import GameplayKit

class ViewController: NSViewController {

    @IBOutlet var skView: SKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let view = self.skView {
            let scene = GameScene(
                size: CGSize(width: Programa.ANCHO_DE_LA_PANTALLA,
                             height: Programa.ALTO_DE_LA_PANTALLA)
            )
            scene.anchorPoint = CGPoint(x: 0, y: 0)
            scene.scaleMode = .aspectFit
            view.presentScene(scene)

            view.ignoresSiblingOrder = true
            // Fondo negro para las barras de letterbox cuando la ventana no es exactamente 4:3.
            view.wantsLayer = true
            view.layer?.backgroundColor = NSColor.black.cgColor

#if DEBUG
            view.showsFPS = true
            view.showsNodeCount = true
#endif
        }
    }
}

