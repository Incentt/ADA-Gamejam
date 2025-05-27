//
//  GameViewController.swift
//  Balanciaga
//
//  Created by Vincent Wisnata on 26/05/25.
//import UIKit
import SpriteKit

class GameViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create and configure the view
        let skView = SKView(frame: view.bounds)
        view.addSubview(skView)
        
        // Create the scene
        let scene = GameScene()
        scene.size = skView.bounds.size
        scene.scaleMode = .aspectFill
        
        // Configure the view
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
        
        // Present the scene
        skView.presentScene(scene)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
