//
//  GameActorBuffer.swift
//  KTerrain
//
//  Created by 哈哈 on 15/10/19.
//  Copyright © 2015年 哈哈. All rights reserved.
//

import Foundation
import Metal
import MetalKit


let MB:Int = 1024 * 1024

enum ShaderIndex:Int{
    case Vertex = 0,Projection,View,Model
}


class GameActorBuffer: NSObject {
    var m_vertex:[Float] = [Float]()
    var m_index = [UInt32]()
    var m_indexBuffer:MTLBuffer! = nil
    var m_vertexBuffer:MTLBuffer! = nil
    var m_scene:GameViewController! = nil
    
    init(scene:GameViewController) {
        super.init()
        m_scene = scene
        //1MB的Buffer
        m_vertexBuffer = m_scene.m_device.newBufferWithLength(1 * MB, options: MTLResourceOptions.CPUCacheModeDefaultCache)
        m_indexBuffer = m_scene.m_device.newBufferWithLength(1 * MB, options: MTLResourceOptions.CPUCacheModeDefaultCache)
    }
    
    
    func addBuffer(vertex:[Float],index:[UInt32]){
        m_vertex += vertex
        m_index += index
        
    }
    
    func updataBuffer(){
        memcpy(m_vertexBuffer.contents(), m_vertex, sizeof(Float) * m_vertex.count)
        memcpy(m_indexBuffer.contents(), m_index, sizeof(UInt32) * m_index.count)
    }
    
    func vertexSize()->Int{
        return m_vertex.count
    }
    
    func indexSize()->Int{
        return m_index.count
    }
}
