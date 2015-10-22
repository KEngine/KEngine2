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
    var m_sun = [Float]()
   
    
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // setup view properties
        m_mtkView = self.view as! MTKView
        m_mtkView.colorPixelFormat = MTLPixelFormat.BGRA8Unorm


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
        /*let actor1   = GameActor(vertex:triangle1_vertex, index: triangle_index, scene: self)
        //actor1.translate(0, y: 0, z: -2)
        actor1.register()
        let actor2   = GameActor(vertex:triangle2_vertex, index: triangle_index, scene: self)
       // actor2.translate(-2, y: 0, z: 0)
        actor2.register()
        let actor3   = GameActor(vertex:triangle3_vertex, index: triangle_index, scene: self)
        //actor3.translate(0, y: 0, z:2)
        actor3.register()
        let actor4   = GameActor(vertex:triangle4_vertex, index: triangle_index, scene: self)
       // actor4.translate(2, y: 0, z: 0)
        actor4.register()*/
        let actor5   = GameActor(vertex: flat_vertex, index: flat_index, scene: self)
        actor5.translate(0, y: -1, z: 0)
        actor5.scale(10)
        actor5.register()
        
        
        /*let actor7   = GameActor(vertex: flat_vertex, index: flat_index, scene: self)
        actor7.scale(2)
        
        actor7.rotate(  90.0 * Float(M_PI) / 180, axis: [0,0,1])
        //actor7.translate(-6, y: 0, z: 0)

        actor7.register()
        
        
        let actor8   = GameActor(vertex: flat_vertex, index: flat_index, scene: self)
        actor8.scale(2)
        actor8.rotate(  -90.0 * Float(M_PI) / 180, axis: [1,0,0])
        //actor8.translate(0, y: 0, z: -7)
        
        actor8.register()*/

        
        //let actor6   = GameActor(vertex: sephere2_vertices, index: sephere_indices, scene: self)
        //actor6.translate(0, y: 1, z: 0)
        //actor6.register()
        

    }
    
    func loadLight(){
        /*let light1 = GameLightActor(vertex: sephere_vertices, index: sephere_indices, pos: [0,0,0], color: [1,0,0], scene: self)
        
        light1.translate(-2, y: 1, z: -2)
        light1.scale(4.5)
        light1.register()
        
        
        let light2 = GameLightActor(vertex: sephere_vertices, index: sephere_indices, pos: [0,0,0], color: [0,1,0], scene: self)
        
        
        light2.translate(2, y: 1, z: 2)
        light2.scale(4.5)
        light2.register()
        
        
        
        let light3 = GameLightActor(vertex: sephere_vertices, index: sephere_indices, pos: [0,0,0], color: [0,0,1], scene: self)
        
        light3.translate(2, y: 1, z: -2)
        light3.scale(4.5)
        light3.register()
        
        
        
        
        let light4 = GameLightActor(vertex: sephere_vertices, index: sephere_indices, pos: [0,0,0], color: [1,1,1], scene: self)
        
        light4.translate(-2, y: 1, z: 2)
        light4.scale(4.5)
        light4.register()
        
        
        
        
        
        
        //print(sephere2_vertices.count)*/
        
        
        for var i = -20 ; i < 20 ; ++i{
            for var j = 20 ; j > -20 ; --j{
                let light = GameLightActor(vertex: sephere_vertices, index: sephere_indices, pos: [0,0,0], color: [0.5 + Float(i) * 0.1,0.5 + Float(j),0.5], scene: self)
                light.translate(Float(i) * 2, y: 1, z: Float(j) * 2)
                light.scale(3.3)
                light.register()
                
                let actor = GameActor(vertex: sephere2_vertices, index: sephere_indices, scene: self)
                actor.translate(Float(i) * 2, y: 1, z: 2 * Float(j))
                actor.scale(1)
                actor.register()

            }
        }
        
        m_sun = [-60,150,-60,0,0,0]

    }
    
    
    func loadCamera(){
        m_camera = GameCamera(pos: [20,20,20], center: [0,0,0], up: [0,1,0], scene: self)
    }
    
    
}
