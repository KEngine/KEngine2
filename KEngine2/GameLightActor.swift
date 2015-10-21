//
//  GameLightActor.swift
//  KEngine2
//
//  Created by 哈哈 on 15/10/20.
//  Copyright © 2015年 哈哈. All rights reserved.
//

import Foundation
import Metal
import MetalKit



class GameLightActor: GameActor {
    var m_lightInfo:[Float]! = nil
    //var m_lightInfoBuffer:GameUniformBuffer! = nil
    init(vertex:[Float],index:[UInt32],pos:[Float],color:[Float],scene:GameViewController){
        super.init(vertex: vertex, index: index, scene: scene)
        m_lightInfo = [pos[0],pos[1],pos[2],color[0],color[1],color[2]]
        //m_lightInfoBuffer = GameUniformBuffer(data: m_lightInfo, scene: scene)
        
        
    }
    
    
    override func renderActor(encoder: MTLRenderCommandEncoder) {
        encoder.setVertexBytes(m_lightInfo, length: sizeofValue(m_lightInfo[0]) * m_lightInfo.count, atIndex: 4)
        //encoder.setVertexBuffer(m_lightInfoBuffer.buffer(), offset: 0, atIndex: 4)
        encoder.setVertexBuffer(m_modelBuffer.buffer(), offset: 0, atIndex: ShaderIndex.Model.rawValue)
        encoder.setVertexBufferOffset(m_vertexOffset * sizeof(Float), atIndex: 0)
        encoder.drawIndexedPrimitives(MTLPrimitiveType.Triangle, indexCount: m_index.count, indexType: MTLIndexType.UInt32, indexBuffer: m_scene.m_actorBuffer.m_indexBuffer, indexBufferOffset: m_indexOffset * sizeofValue(m_index[0]))
    }
    override func register() {
        m_scene.m_render.m_lights.append(self)
    }
}