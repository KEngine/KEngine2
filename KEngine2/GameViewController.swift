//
//  GameViewController.swift
//  KEngine2
//
//  Created by 哈哈 on 15/10/19.
//  Copyright © 2015年 哈哈. All rights reserved.
//

import UIKit
import Metal
import MetalKit



class GameViewController:UIViewController{
    
    let m_device: MTLDevice = MTLCreateSystemDefaultDevice()!
    var m_render:GameRender! = nil
    var m_mtkView:MTKView! = nil
    var m_actorBuffer:GameActorBuffer! = nil
    var m_camera:GameCamera! = nil
   
    
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // setup view properties
        m_mtkView = self.view as! MTKView


        m_mtkView.device = m_device;
        
        m_render = GameRender(scene: self)

        m_mtkView.delegate = m_render
        loadAssets()
    }
    
    func loadAssets() {
       loadCamera()
        m_actorBuffer = GameActorBuffer(scene: self)
        loadActor()
        loadLight()
    
        
    }
    func loadActor(){
        let actor1   = GameActor(vertex:triangle1_vertex, index: triangle_index, scene: self)
        actor1.translate(0, y: 0, z: -2)
        actor1.register()
        let actor2   = GameActor(vertex:triangle2_vertex, index: triangle_index, scene: self)
        actor2.translate(-2, y: 0, z: 0)
        actor2.register()
        let actor3   = GameActor(vertex:triangle3_vertex, index: triangle_index, scene: self)
        actor3.translate(0, y: 0, z:2)
        actor3.register()
        let actor4   = GameActor(vertex:triangle4_vertex, index: triangle_index, scene: self)
        actor4.translate(2, y: 0, z: 0)
        actor4.register()
        let actor5   = GameActor(vertex: flat_vertex, index: flat_index, scene: self)
        actor5.translate(0, y: -1, z: 0)
        actor5.register()
        
        let actor6   = GameActor(vertex: sephere1_vertices, index: sephere_indices, scene: self)
        actor6.translate(0, y: -1, z: 0)
        actor6.register()
        

    }
    
    func loadLight(){
        let light1 = GameLightActor(vertex: sephere_vertices, index: sephere_indices, pos: [0,0,0], color: [1,1,1], scene: self)
        light1.scale(5)
        light1.translate(0, y: 0, z: 0)
        light1.register()
        
    }
    
    
    func loadCamera(){
        m_camera = GameCamera(pos: [5,5,5], center: [0,0,0], up: [0,1,0], scene: self)
    }
    
    
}
