//
//  GameViewController.swift
//  QuickHull
//
//  Created by Carl Wieland on 4/20/15.
//  Copyright (c) 2015 Carl Wieland. All rights reserved.
//

import SceneKit
import QuartzCore
import QHull

class GameViewController: NSViewController {
    
    @IBOutlet weak var gameView: GameView!
    
    override func awakeFromNib(){
        // create a new scene
        let scene = SCNScene()
        
        // create and add a camera to the scene
//        let cameraNode = SCNNode()
//        cameraNode.camera = SCNCamera()
//        
//        scene.rootNode.addChildNode(cameraNode)
//        
        // place the camera
//        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
//        // create and add a light to the scene
//        let lightNode = SCNNode()
//        lightNode.light = SCNLight()
//        lightNode.light!.type = SCNLightTypeOmni
//        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
//        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = NSColor.lightGrayColor()
        scene.rootNode.addChildNode(ambientLightNode)
//
//        // retrieve the ship node
//        let ship = scene.rootNode.childNodeWithName("ship", recursively: true)!
//        
        var points = [Vector3]()
        for i in 0..<70{
            points.append(randomPointOnSphere() * 5)
        }
        
        let iscosphere = MeshUtils.convexHullOfPoints(points)
        scene.rootNode.addChildNode(iscosphere)
        // animate the 3d object
        let animation = CABasicAnimation(keyPath: "rotation")
        animation.toValue = NSValue(SCNVector4: SCNVector4(x: CGFloat(0), y: CGFloat(1), z: CGFloat(0), w: CGFloat(M_PI)*2))
        animation.duration = 10
        animation.repeatCount = MAXFLOAT //repeat forever
//        iscosphere.addAnimation(animation, forKey: nil)

        // set the scene to the view
        self.gameView!.scene = scene
        
        // allows the user to manipulate the camera
        self.gameView!.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        self.gameView!.showsStatistics = true
//        gameView.autoenablesDefaultLighting = true


        // configure the view
        self.gameView!.backgroundColor = NSColor.whiteColor()
        
       
    }

}
