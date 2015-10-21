//
//  GameRender.swift
//  KEngine2
//
//  Created by 哈哈 on 15/10/19.
//  Copyright © 2015年 哈哈. All rights reserved.
//

import Foundation
import Metal
import MetalKit



class GameRender: NSObject,MTKViewDelegate{
    
    var m_scene:GameViewController! = nil
    let m_inflightSemaphore = dispatch_semaphore_create(3)
    var m_bufferIndex = 0
    var m_commandQueue:MTLCommandQueue! = nil
    var m_colorattachmentDesc = MTLRenderPassColorAttachmentDescriptor()
    var m_renderpassDesc = MTLRenderPassDescriptor()
    
    
    var m_gBufferPassDesc = MTLRenderPassDescriptor()
    var m_gBufferPipelineState:MTLRenderPipelineState! = nil
    var m_gBufferDepthStencilState:MTLDepthStencilState! = nil
    
    var m_lightMaskDepthStencilState:MTLDepthStencilState! = nil
    var m_lightColorDepthStencilState:MTLDepthStencilState! = nil
    var m_lightColorDepthStencilStateNoDepth:MTLDepthStencilState! = nil
    var m_lightMaskPipelineState:MTLRenderPipelineState! = nil
    var m_lightColorPipelineState:MTLRenderPipelineState! = nil
    
    var m_depthStencilDesc = MTLDepthStencilDescriptor()
    var m_stencilStateDesc = MTLStencilDescriptor()
    var m_renderToScreenDepthStencilState:MTLDepthStencilState! = nil
    var m_renderPipelineStateDesc = MTLRenderPipelineDescriptor()
    var m_renderToScreenPipelineState:MTLRenderPipelineState! = nil
    var m_textureDesc = MTLTextureDescriptor()
    var m_library:MTLLibrary! = nil
    var m_actors:[GameActor]! = nil
    var m_lights:[GameLightActor]! = nil
    var m_changeSize = false
    var m_size = CGSize(width: 0, height: 0)
    var m_deptAttachmentDesc = MTLRenderPassDepthAttachmentDescriptor()
    var m_stencilAttachmentDesc = MTLRenderPassStencilAttachmentDescriptor()
    init(scene:GameViewController) {
        super.init()
        m_scene = scene
        m_commandQueue = m_scene.m_device.newCommandQueue()
        m_library = m_scene.m_device.newDefaultLibrary()
        m_actors = [GameActor]()
        m_lights = [GameLightActor]()
        setGbufferState()
        setLightState()
        setRenderToScreenPipelineState()
        
        
    }
    
    
    
    func drawInMTKView(view: MTKView) {
        
        // print("update")
        dispatch_semaphore_wait(m_inflightSemaphore, DISPATCH_TIME_FOREVER)
        
        
        let commandBuffer = m_commandQueue.commandBuffer()
        commandBuffer.label = "Frame command buffer"
        
        
        commandBuffer.addCompletedHandler{ [weak self] commandBuffer in
            if let strongSelf = self {
                dispatch_semaphore_signal(strongSelf.m_inflightSemaphore)
            }
            return
        }
        
        
        let gBufferRenderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(gBufferPass())
        renderActorsToGbuffer(gBufferRenderEncoder)
        renderLight(gBufferRenderEncoder)
        gBufferRenderEncoder.endEncoding()

        
        
        let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderToScreenPassDesc())
        renderActorsToScreen(renderEncoder)
        renderEncoder.endEncoding()
        commandBuffer.presentDrawable(view.currentDrawable!)
        commandBuffer.commit()
        m_bufferIndex++
        
    }
    
    func gBufferPass()->MTLRenderPassDescriptor{
        if m_changeSize{
            
            //不用render to texture
            m_gBufferPassDesc.colorAttachments[0] = nil
            
            let textureDesc = m_textureDesc
            textureDesc.width = Int(m_size.width)
            textureDesc.height = Int(m_size.height)
            textureDesc.textureType = MTLTextureType.Type2D
            
            
            textureDesc.pixelFormat = MTLPixelFormat.RGBA16Float
            
            m_colorattachmentDesc.texture = m_scene.m_device.newTextureWithDescriptor(textureDesc)
            m_colorattachmentDesc.loadAction = MTLLoadAction.Clear
            m_colorattachmentDesc.storeAction = MTLStoreAction.DontCare
            m_colorattachmentDesc.clearColor = MTLClearColorMake(1, 1, 1, 1)
            m_gBufferPassDesc.colorAttachments[1] = m_colorattachmentDesc
            
            textureDesc.pixelFormat = MTLPixelFormat.RGBA16Float
            
            m_colorattachmentDesc.texture = m_scene.m_device.newTextureWithDescriptor(textureDesc)
            m_colorattachmentDesc.loadAction = MTLLoadAction.Clear
            m_colorattachmentDesc.storeAction = MTLStoreAction.DontCare
            m_colorattachmentDesc.clearColor = MTLClearColorMake(1, 1, 1, 1)
            m_gBufferPassDesc.colorAttachments[2] = m_colorattachmentDesc
            
            textureDesc.pixelFormat = MTLPixelFormat.RGBA16Float
            
            m_colorattachmentDesc.texture = m_scene.m_device.newTextureWithDescriptor(textureDesc)
            m_colorattachmentDesc.loadAction = MTLLoadAction.Clear
            m_colorattachmentDesc.storeAction = MTLStoreAction.DontCare
            m_colorattachmentDesc.clearColor = MTLClearColorMake(1, 1, 1, 1)
            m_gBufferPassDesc.colorAttachments[3] = m_colorattachmentDesc
            
            textureDesc.pixelFormat = MTLPixelFormat.RGBA16Float
            
            m_colorattachmentDesc.texture = m_scene.m_device.newTextureWithDescriptor(textureDesc)
            m_colorattachmentDesc.loadAction = MTLLoadAction.Clear
            m_colorattachmentDesc.storeAction = MTLStoreAction.DontCare
            m_colorattachmentDesc.clearColor = MTLClearColorMake(1, 1, 1, 1)
            m_gBufferPassDesc.colorAttachments[4] = m_colorattachmentDesc

            
            
            
            
            textureDesc.pixelFormat = MTLPixelFormat.Depth32Float_Stencil8
            
            let deptAttachmentDesc = m_deptAttachmentDesc
            deptAttachmentDesc.texture = m_scene.m_device.newTextureWithDescriptor(textureDesc)
            deptAttachmentDesc.loadAction = MTLLoadAction.Clear
            deptAttachmentDesc.storeAction = MTLStoreAction.DontCare
            deptAttachmentDesc.clearDepth = 1
            
            
            let stencilAttachmentDesc = m_stencilAttachmentDesc
            stencilAttachmentDesc.texture = deptAttachmentDesc.texture
            stencilAttachmentDesc.loadAction = MTLLoadAction.Clear
            stencilAttachmentDesc.storeAction = MTLStoreAction.DontCare
            stencilAttachmentDesc.clearStencil = 0
            //let depthStencilDesc = m_scene.m_utility.m_descriptor.m_deptAttachmentDesc
            
            
            
            m_gBufferPassDesc.depthAttachment = deptAttachmentDesc
            m_gBufferPassDesc.stencilAttachment = stencilAttachmentDesc
            
            m_changeSize = false
        }
        return m_gBufferPassDesc
    
    }
    
    
    func setLightState(){
        let renderpipelineDesc = m_renderPipelineStateDesc
        let depthStencilDesc = m_depthStencilDesc
        let stencilState = m_stencilStateDesc
        
        depthStencilDesc.depthWriteEnabled = false
        stencilState.stencilCompareFunction = MTLCompareFunction.Equal
        stencilState.stencilFailureOperation = MTLStencilOperation.Keep
        stencilState.depthFailureOperation = MTLStencilOperation.IncrementClamp
        stencilState.depthStencilPassOperation = MTLStencilOperation.Keep
        stencilState.writeMask = 0xFF
        stencilState.readMask = 0xFF
        depthStencilDesc.depthCompareFunction = MTLCompareFunction.LessEqual
        depthStencilDesc.frontFaceStencil = stencilState
        depthStencilDesc.backFaceStencil = stencilState
        m_lightMaskDepthStencilState = m_scene.m_device.newDepthStencilStateWithDescriptor(depthStencilDesc)
        
        
        
        depthStencilDesc.depthWriteEnabled = false
        stencilState.stencilCompareFunction = MTLCompareFunction.Less
        stencilState.stencilFailureOperation = MTLStencilOperation.Keep
        stencilState.depthFailureOperation = MTLStencilOperation.DecrementClamp
        stencilState.depthStencilPassOperation = MTLStencilOperation.DecrementClamp
        stencilState.writeMask = 0xFF
        stencilState.readMask = 0xFF
        depthStencilDesc.depthCompareFunction = MTLCompareFunction.LessEqual
        depthStencilDesc.frontFaceStencil = stencilState
        depthStencilDesc.backFaceStencil = stencilState
        m_lightColorDepthStencilState = m_scene.m_device.newDepthStencilStateWithDescriptor(depthStencilDesc)
        
        depthStencilDesc.depthCompareFunction = MTLCompareFunction.Always
        m_lightColorDepthStencilStateNoDepth = m_scene.m_device.newDepthStencilStateWithDescriptor(depthStencilDesc)
        
        renderpipelineDesc.label = "Light Mask Render"
        renderpipelineDesc.vertexFunction = m_library.newFunctionWithName("lightVertex")
        renderpipelineDesc.fragmentFunction = nil
        for var i = 1 ; i <= 4 ; ++i{
            renderpipelineDesc.colorAttachments[i].writeMask = MTLColorWriteMask.None
        }
        do{
            m_lightMaskPipelineState = try m_scene.m_device.newRenderPipelineStateWithDescriptor(renderpipelineDesc)
        }catch let error as NSError{
            fatalError(error.localizedDescription)
        }
        
        renderpipelineDesc.label = "Light Color Render"
        renderpipelineDesc.vertexFunction = m_library.newFunctionWithName("lightVertex")
        renderpipelineDesc.fragmentFunction = m_library.newFunctionWithName("lightFragment")!
        for var i = 1 ; i <= 4 ; ++i{
            renderpipelineDesc.colorAttachments[i].writeMask = MTLColorWriteMask.All
        }
        do{
            m_lightColorPipelineState = try m_scene.m_device.newRenderPipelineStateWithDescriptor(renderpipelineDesc)
        }catch let error as NSError{
            fatalError(error.localizedDescription)
        }

    }
    
    
    
    func setGbufferState(){
        let renderPipelineDesc = m_renderPipelineStateDesc
        renderPipelineDesc.vertexFunction = m_library.newFunctionWithName("gbufferVertex")
        renderPipelineDesc.fragmentFunction = m_library.newFunctionWithName("gbufferFragment")
        
        
        renderPipelineDesc.colorAttachments[0].pixelFormat = MTLPixelFormat.Invalid
        renderPipelineDesc.colorAttachments[1].pixelFormat = MTLPixelFormat.RGBA16Float
        renderPipelineDesc.colorAttachments[2].pixelFormat = MTLPixelFormat.RGBA16Float
        renderPipelineDesc.colorAttachments[3].pixelFormat = MTLPixelFormat.RGBA16Float
        renderPipelineDesc.colorAttachments[4].pixelFormat = MTLPixelFormat.RGBA16Float

        //m_scene.m_mtkView.colorPixelFormat
        //renderPipelineDesc.colorAttachments[3].pixelFormat = m_scene.m_mtkView.colorPixelFormat
        
        
        renderPipelineDesc.depthAttachmentPixelFormat = MTLPixelFormat.Depth32Float_Stencil8
        renderPipelineDesc.stencilAttachmentPixelFormat = MTLPixelFormat.Depth32Float_Stencil8
        
        do{
            m_gBufferPipelineState = try m_scene.m_device.newRenderPipelineStateWithDescriptor(renderPipelineDesc)
        }catch let error as NSError{
            print("(GameDefferedRender.swift setupGeometryState() function) :\(error.localizedDescription),\(error.localizedRecoverySuggestion)")
        }
        
        
        let depthStencilDesc = m_depthStencilDesc
        let stencilState = m_stencilStateDesc
        depthStencilDesc.depthWriteEnabled = true
        depthStencilDesc.depthCompareFunction = MTLCompareFunction.LessEqual
        stencilState.stencilCompareFunction = MTLCompareFunction.Always
        stencilState.stencilFailureOperation = MTLStencilOperation.Keep
        stencilState.depthFailureOperation = MTLStencilOperation.Keep
        stencilState.depthStencilPassOperation = MTLStencilOperation.Replace
        stencilState.readMask = 0xFF
        stencilState.writeMask = 0xFF
        depthStencilDesc.frontFaceStencil = stencilState
        depthStencilDesc.backFaceStencil = stencilState
        
        
        m_gBufferDepthStencilState = m_scene.m_device.newDepthStencilStateWithDescriptor(depthStencilDesc)
    }

    
    
    
    
    func renderToScreenPassDesc()->MTLRenderPassDescriptor{
        let renderPassDesc = m_renderpassDesc
        renderPassDesc.colorAttachments[0].texture = m_scene.m_mtkView.currentDrawable!.texture
        renderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
        renderPassDesc.colorAttachments[0].loadAction  = MTLLoadAction.Clear
        renderPassDesc.colorAttachments[0].storeAction = MTLStoreAction.Store
        
        
        return renderPassDesc
    }
    
    
    func setRenderToScreenPipelineState(){
        let renderPipelineDesc = m_renderPipelineStateDesc
        renderPipelineDesc.colorAttachments[0].pixelFormat = m_scene.m_mtkView.colorPixelFormat
        renderPipelineDesc.colorAttachments[1] = nil
        renderPipelineDesc.colorAttachments[2] = nil
        renderPipelineDesc.colorAttachments[3] = nil
        renderPipelineDesc.colorAttachments[4] = nil

        renderPipelineDesc.depthAttachmentPixelFormat = MTLPixelFormat.Invalid
        renderPipelineDesc.stencilAttachmentPixelFormat = MTLPixelFormat.Invalid

        renderPipelineDesc.vertexFunction = m_library.newFunctionWithName("passThroughVertex")
        renderPipelineDesc.fragmentFunction = m_library.newFunctionWithName("passThroughFragment")
        //renderPipelineDesc.depthAttachmentPixelFormat = MTLPixelFormat.Depth32Float
        do{
            m_renderToScreenPipelineState = try m_scene.m_device.newRenderPipelineStateWithDescriptor(renderPipelineDesc)
        }catch let error as NSError{
            fatalError("RenderPipelineState Error \(error.localizedDescription)")
        }
        
        let depthStencilDesc = MTLDepthStencilDescriptor()
        depthStencilDesc.depthWriteEnabled = true
        depthStencilDesc.depthCompareFunction = MTLCompareFunction.LessEqual
        m_renderToScreenDepthStencilState = m_scene.m_device.newDepthStencilStateWithDescriptor(depthStencilDesc)
    }

    
    func renderActorsToScreen(renderEncoder:MTLRenderCommandEncoder){
        renderEncoder.setCullMode(.Back)
        renderEncoder.setVertexBuffer(m_scene.m_camera.projectionBuffer(), offset: 0, atIndex: ShaderIndex.Projection.rawValue)
        renderEncoder.setVertexBuffer(m_scene.m_camera.viewBuffer(), offset: 0, atIndex: ShaderIndex.View.rawValue)
        renderEncoder.setDepthStencilState(m_renderToScreenDepthStencilState)
        if m_actors.count == 0 {
            print("There Is No Actor")
        }else{
            m_scene.m_actorBuffer.updataBuffer()
            renderEncoder.setVertexBuffer(m_scene.m_actorBuffer.m_vertexBuffer, offset: 0, atIndex: ShaderIndex.Vertex.rawValue)
            renderEncoder.setRenderPipelineState(m_renderToScreenPipelineState)
            var i:Float = -4.0
            for actor in m_actors{
                actor.rotate(i * Float(0.01), axis: [0,1,0])
                actor.renderActor(renderEncoder)
                i++
            }
        }
    }
    
    func renderActorsToGbuffer(renderEncoder:MTLRenderCommandEncoder){
        renderEncoder.label = "GBuffer"
        renderEncoder.setStencilReferenceValue(128)
        renderEncoder.setCullMode(.Back)

        if m_actors.count == 0 {
            print("There Is No Actor")
        }else{
            renderEncoder.setVertexBuffer(m_scene.m_camera.projectionBuffer(), offset: 0, atIndex: ShaderIndex.Projection.rawValue)
            renderEncoder.setVertexBuffer(m_scene.m_camera.viewBuffer(), offset: 0, atIndex: ShaderIndex.View.rawValue)
            renderEncoder.setDepthStencilState(m_gBufferDepthStencilState)
            m_scene.m_actorBuffer.updataBuffer()
            renderEncoder.setVertexBuffer(m_scene.m_actorBuffer.m_vertexBuffer, offset: 0, atIndex: ShaderIndex.Vertex.rawValue)
            renderEncoder.setRenderPipelineState(m_gBufferPipelineState)
            var i:Float = -4.0
            for actor in m_actors{
                actor.rotate(i * Float(0.01), axis: [0,1,0])
                actor.renderActor(renderEncoder)
                i++
            }
        }
    }
    
    func renderLight(renderEncoder:MTLRenderCommandEncoder){
        renderEncoder.label = "Light"

        
        
        if m_lights.count == 0{
            print("There is no light")
        }else{
            renderEncoder.setVertexBuffer(m_scene.m_camera.projectionBuffer(), offset: 0, atIndex: ShaderIndex.Projection.rawValue)
            renderEncoder.setVertexBuffer(m_scene.m_camera.viewBuffer(), offset: 0, atIndex: ShaderIndex.View.rawValue)
            
            renderEncoder.setFragmentBuffer(m_scene.m_camera.viewBuffer(), offset: 0, atIndex: 1)

            for light in m_lights{
                //stencil
                renderEncoder.pushDebugGroup("stencil")
                renderEncoder.setCullMode(MTLCullMode.Front)
                renderEncoder.setStencilReferenceValue(128)

                renderEncoder.setRenderPipelineState(m_lightMaskPipelineState)
                renderEncoder.setDepthStencilState(m_lightMaskDepthStencilState)
                light.renderActor(renderEncoder)
            
                renderEncoder.popDebugGroup()
                //color
                
                renderEncoder.pushDebugGroup("Color")
                renderEncoder.setCullMode(.Front)
                renderEncoder.setStencilReferenceValue(128)

                renderEncoder.setRenderPipelineState(m_lightColorPipelineState)
                renderEncoder.setDepthStencilState(m_lightColorDepthStencilStateNoDepth)
                light.renderActor(renderEncoder)

                renderEncoder.popDebugGroup()
                
            }

        }
        
    }


    
    
    
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        m_changeSize = true
        m_size = size
        m_scene.m_camera.changeSize()
    }

}