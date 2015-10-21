//
//  GameCamera.swift
//  KEngine
//
//  Created by 哈哈 on 15/8/29.
//  Copyright © 2015年 哈哈. All rights reserved.
//

import Foundation
import Metal
import MetalKit




class GameCamera:NSObject{
    var m_viewMatrix = float4x4(1)
    var m_projectionMatrix = float4x4(1)
    var m_sunViewMatrix = float4x4(1)
    var m_viewBuffer:GameUniformBuffer! = nil
    var m_projectionBuffer:GameUniformBuffer! = nil
    var m_sunViewBuffer:GameUniformBuffer! = nil
    
    var m_scene:GameViewController! = nil
    var m_pos:[Float]! = nil
    
    
    
    
    
    init(pos:[Float],center:[Float],up:[Float],scene:GameViewController) {
        super.init()
        m_scene = scene
        m_pos = pos
        m_viewMatrix.matrixFromLookAt(m_pos, center: center, up: up)
        m_projectionMatrix.MatrixMakeFrustum_oc(-1, right: 1, bottom: -Float(scene.view.frame.width / scene.view.frame.height), top: Float(scene.view.frame.width / scene.view.frame.height), near: 0.1, far: -1000)
        m_viewBuffer = GameUniformBuffer(data: m_viewMatrix.dumpToSwift(), scene: scene)
        m_projectionBuffer = GameUniformBuffer(data: m_projectionMatrix.dumpToSwift(), scene: scene)
    }
    
    
        
    
    func changeSize(){
        m_projectionMatrix.MatrixMakeFrustum_oc(-1, right: 1, bottom: -Float(m_scene.view.frame.width / m_scene.view.frame.height), top: Float(m_scene.view.frame.width / m_scene.view.frame.height), near: 0.1, far: -1000)
        m_projectionBuffer.updateBuffer(m_projectionMatrix.dumpToSwift())
    }
    
    func viewBuffer()->MTLBuffer{
        return  m_viewBuffer.buffer()
    }
    
    
    func projectionBuffer()->MTLBuffer{
        return m_projectionBuffer.buffer()
    }
    
}