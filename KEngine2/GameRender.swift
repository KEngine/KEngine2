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



let inscribe:Float = 0.755761314076171;    // sqrtf(3.0) / 12.0 * (3.0 + sqrtf(5.0))
let circumscribe:Float = 0.951056516295154; // 0.25 * sqrtf(10.0 + 2.0 * sqrtf(5.0))



class GameRender: NSObject,MTKViewDelegate{
    
    var m_scene:GameViewController! = nil
    let m_inflightSemaphore = dispatch_semaphore_create(3)
    var m_bufferIndex = 0
    var m_commandQueue:MTLCommandQueue! = nil
    var m_colorattachmentDesc = MTLRenderPassColorAttachmentDescriptor()
    var m_renderpassDesc = MTLRenderPassDescriptor()
    
    
    
    
    var m_shadowMap:MTLTexture! = nil
    var m_shadowMapBlur:MTLTexture! = nil
    var m_shadowPass = MTLRenderPassDescriptor()
    var m_shadowPipelieState:MTLRenderPipelineState! = nil
    var m_shadowDepthStencilState:MTLDepthStencilState! = nil

    
    var m_gBufferPassDesc = MTLRenderPassDescriptor()
    var m_gBufferPipelineState:MTLRenderPipelineState! = nil
    var m_gBufferDepthStencilState:MTLDepthStencilState! = nil
    
    var m_lightMaskDepthStencilState:MTLDepthStencilState! = nil
    var m_lightColorDepthStencilState:MTLDepthStencilState! = nil
    var m_lightColorDepthStencilStateNoDepth:MTLDepthStencilState! = nil
    var m_lightMaskPipelineState:MTLRenderPipelineState! = nil
    var m_lightColorPipelineState:MTLRenderPipelineState! = nil
    
    
    var m_compositionPipelineState:MTLRenderPipelineState! = nil
    var m_compositionDepthStencilState:MTLDepthStencilState! = nil
    var m_gBufferTexture:MTLTexture! = nil
    
    
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
    var m_compositionVertexBuffer:MTLBuffer! = nil
    var m_renderToScreenBuffer:MTLBuffer! = nil
    
    //var m_mtktextureLoader:MTKTextureLoader! = nil

    
    
    init(scene:GameViewController) {
        super.init()
        m_scene = scene
        m_commandQueue = m_scene.m_device.newCommandQueue()
        m_library = m_scene.m_device.newDefaultLibrary()
        m_actors = [GameActor]()
        m_lights = [GameLightActor]()
        //m_mtktextureLoader = MTKTextureLoader(device:m_scene.m_device)

        shadowPassDesc()
        //setShadowState()
        setGbufferState()
        setLightState()
        setCompostionState()
        //setRenderToScreenPipelineState()
        
        
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
        
        
        let gBufferRenderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(gBufferPass(view.currentDrawable!.texture))
        renderActorsToGbuffer(gBufferRenderEncoder)
        renderLight(gBufferRenderEncoder)
        composition(gBufferRenderEncoder)
        gBufferRenderEncoder.endEncoding()

        
        
        /*let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderToScreenPassDesc())
        //renderActorsToScreen(renderEncoder)
        renderSceneToScreen(renderEncoder)*/
        //renderEncoder.endEncoding()
        commandBuffer.presentDrawable(view.currentDrawable!)
        commandBuffer.commit()
        m_bufferIndex++
        
    }
    
    
    func shadowPassDesc()->MTLRenderPassDescriptor{
        let textureDesc = m_textureDesc
        textureDesc.textureType = MTLTextureType.Type2D
        textureDesc.width = Int(1024)
        textureDesc.height = Int(1024)
        textureDesc.mipmapLevelCount = 1
        textureDesc.pixelFormat = MTLPixelFormat.Depth32Float
        m_shadowMap = m_scene.m_device.newTextureWithDescriptor(textureDesc)
        
        
        
        m_shadowMapBlur = m_scene.m_device.newTextureWithDescriptor(textureDesc)
        /*m_shadowPass.colorAttachments[0].texture = m_shadowMap
        m_shadowPass.colorAttachments[0].storeAction = .Store
        m_shadowPass.colorAttachments[0].loadAction = MTLLoadAction.Clear
        m_shadowPass.colorAttachments[0].clearColor = MTLClearColorMake(0,0,0,1)*/
        m_shadowPass.depthAttachment.texture = m_shadowMap
        m_shadowPass.depthAttachment.storeAction = MTLStoreAction.Store
        m_shadowPass.depthAttachment.loadAction = MTLLoadAction.Clear
        m_shadowPass.depthAttachment.clearDepth = 1.0
        
        
        /*textureDesc.textureType = MTLTextureType.Type2D
        textureDesc.width = Int(1024)
        textureDesc.height = Int(1024)
        textureDesc.mipmapLevelCount = 1
        textureDesc.pixelFormat = MTLPixelFormat.Depth32Float
        m_depthAttach = m_scene.m_device.newTextureWithDescriptor(textureDesc)
        m_shadowPass.depthAttachment.texture = m_depthAttach
        m_shadowPass.depthAttachment.storeAction = MTLStoreAction.Store
        m_shadowPass.depthAttachment.loadAction = MTLLoadAction.Clear
        m_shadowPass.depthAttachment.clearDepth = 1.0*/
        
        
        return m_shadowPass
    }
    
    func setShadowState(){
        let shadowPipelineStateDesc = m_renderPipelineStateDesc
        shadowPipelineStateDesc.vertexFunction = m_library.newFunctionWithName("renderShadowMapVertex")
        shadowPipelineStateDesc.fragmentFunction = m_library.newFunctionWithName("renderShadowMapFragment")
        //shadowPipelineStateDesc.colorAttachments[0].pixelFormat = m_shadowMap.pixelFormat
        shadowPipelineStateDesc.depthAttachmentPixelFormat = MTLPixelFormat.Depth32Float
        
        do{
            try m_shadowPipelieState = m_scene.m_device.newRenderPipelineStateWithDescriptor(shadowPipelineStateDesc)
        }catch let error as NSError{
            fatalError(error.localizedDescription)
        }
        
        
        let depthStencilDesc = m_depthStencilDesc
        depthStencilDesc.depthWriteEnabled = true
        depthStencilDesc.depthCompareFunction = MTLCompareFunction.LessEqual
        m_shadowDepthStencilState = m_scene.m_device.newDepthStencilStateWithDescriptor(depthStencilDesc)
    }

    
    
    
    
    
    func gBufferPass(texture:MTLTexture)->MTLRenderPassDescriptor{
        m_colorattachmentDesc.texture = texture
        m_colorattachmentDesc.loadAction = MTLLoadAction.Clear
        m_colorattachmentDesc.storeAction = MTLStoreAction.Store
        m_colorattachmentDesc.clearColor = MTLClearColorMake(0, 0, 0, 1)
        m_gBufferPassDesc.colorAttachments[0] = m_colorattachmentDesc
        
        //return renderPassDesc
        
        
        if m_changeSize{
            
            //不用render to texture
            //m_gBufferPassDesc.colorAttachments[0] = nil
            
            let textureDesc = m_textureDesc
            textureDesc.width = Int(m_size.width)
            textureDesc.height = Int(m_size.height)
            textureDesc.textureType = MTLTextureType.Type2D
            
            
            textureDesc.pixelFormat = MTLPixelFormat.BGRA8Unorm
            
            m_colorattachmentDesc.texture = m_scene.m_device.newTextureWithDescriptor(textureDesc)
            m_colorattachmentDesc.loadAction = MTLLoadAction.Clear
            m_colorattachmentDesc.storeAction = MTLStoreAction.DontCare
            m_colorattachmentDesc.clearColor = MTLClearColorMake(0, 0, 0, 1)
            m_gBufferPassDesc.colorAttachments[1] = m_colorattachmentDesc
            
            textureDesc.pixelFormat = MTLPixelFormat.BGRA8Unorm
            
            m_colorattachmentDesc.texture = m_scene.m_device.newTextureWithDescriptor(textureDesc)
            m_colorattachmentDesc.loadAction = MTLLoadAction.Clear
            m_colorattachmentDesc.storeAction = MTLStoreAction.DontCare
            m_colorattachmentDesc.clearColor = MTLClearColorMake(0, 0, 0, 1)
            m_gBufferPassDesc.colorAttachments[2] = m_colorattachmentDesc
            
            textureDesc.pixelFormat = MTLPixelFormat.R32Float
            m_colorattachmentDesc.texture = m_scene.m_device.newTextureWithDescriptor(textureDesc)
            m_colorattachmentDesc.loadAction = MTLLoadAction.Clear
            m_colorattachmentDesc.storeAction = MTLStoreAction.DontCare
            m_colorattachmentDesc.clearColor = MTLClearColorMake(0, 0, 0, 1)
            m_gBufferPassDesc.colorAttachments[3] = m_colorattachmentDesc
            
            /*textureDesc.pixelFormat = MTLPixelFormat.RGBA16Float
            
            m_colorattachmentDesc.texture = m_scene.m_device.newTextureWithDescriptor(textureDesc)
            m_colorattachmentDesc.loadAction = MTLLoadAction.Clear
            m_colorattachmentDesc.storeAction = MTLStoreAction.DontCare
            m_colorattachmentDesc.clearColor = MTLClearColorMake(1, 1, 1, 1)
            m_gBufferPassDesc.colorAttachments[4] = m_colorattachmentDesc*/

            
            
            
            
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
        for var i = 0 ; i <= 3 ; ++i{
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
        for var i = 0 ; i <= 3 ; ++i{
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
        
        
        renderPipelineDesc.colorAttachments[0].pixelFormat = m_scene.m_mtkView.colorPixelFormat
        renderPipelineDesc.colorAttachments[1].pixelFormat = MTLPixelFormat.BGRA8Unorm
        renderPipelineDesc.colorAttachments[2].pixelFormat = MTLPixelFormat.BGRA8Unorm
        renderPipelineDesc.colorAttachments[3].pixelFormat = MTLPixelFormat.R32Float
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

    func setCompostionState(){
        
        
        
        let renderPipelineDesc = m_renderPipelineStateDesc
        renderPipelineDesc.vertexFunction = m_library.newFunctionWithName("CompositonVertex")
        renderPipelineDesc.fragmentFunction = m_library.newFunctionWithName("CompositionFragment")
        do{
            m_compositionPipelineState = try m_scene.m_device.newRenderPipelineStateWithDescriptor(renderPipelineDesc)
        }catch let error as NSError{
            print("(GameDefferedRender.swift setupComposition() function) :\(error.localizedDescription)")
            
        }
        let depthStencilDesc = m_depthStencilDesc
        let stencilState = m_stencilStateDesc
        
        depthStencilDesc.depthWriteEnabled = false
        stencilState.stencilCompareFunction = MTLCompareFunction.Equal
        stencilState.stencilFailureOperation = .Keep
        stencilState.depthFailureOperation = .Keep
        stencilState.depthStencilPassOperation = .Keep
        stencilState.readMask = 0xFF
        stencilState.writeMask = 0
        depthStencilDesc.frontFaceStencil = stencilState
        depthStencilDesc.backFaceStencil = stencilState
        m_compositionDepthStencilState = m_scene.m_device.newDepthStencilStateWithDescriptor(depthStencilDesc)
        
        
        //m_compositionVertexBuffer = m_scene.m_device.newBufferWithBytes(screen_vertex1, length: sizeofValue(screen_vertex1[0]) * screen_vertex1.count, options: MTLResourceOptions.CPUCacheModeDefaultCache)
    }

    
    
    
    /*func renderToScreenPassDesc()->MTLRenderPassDescriptor{
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

        renderPipelineDesc.vertexFunction = m_library.newFunctionWithName("renderToScreenVertex")
        renderPipelineDesc.fragmentFunction = m_library.newFunctionWithName("renderToScreenFragment")
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
        //m_renderToScreenBuffer = m_scene.m_device.newBufferWithBytes(screen_vertex, length: sizeofValue(screen_vertex[0]) * screen_vertex.count, options: MTLResourceOptions.CPUCacheModeDefaultCache)
    }*/

    
        
    func renderActorsToGbuffer(renderEncoder:MTLRenderCommandEncoder){
        renderEncoder.label = "GBuffer"
        renderEncoder.setStencilReferenceValue(128)
        renderEncoder.setCullMode(.Back)

        if m_actors.count == 0 {
            return
        }else{
            renderEncoder.setVertexBuffer(m_scene.m_camera.projectionBuffer(), offset: 0, atIndex: ShaderIndex.Projection.rawValue)
            renderEncoder.setVertexBuffer(m_scene.m_camera.viewBuffer(), offset: 0, atIndex: ShaderIndex.View.rawValue)
            renderEncoder.setDepthStencilState(m_gBufferDepthStencilState)
            m_scene.m_actorBuffer.updataBuffer()
            renderEncoder.setVertexBuffer(m_scene.m_actorBuffer.m_vertexBuffer, offset: 0, atIndex: ShaderIndex.Vertex.rawValue)
            renderEncoder.setRenderPipelineState(m_gBufferPipelineState)
            var i:Float = -4.0
            //m_actors[5].rotate(0.02, axis: [0,0,1])
            for actor in m_actors{
                //actor.rotate(i * Float(0.01), axis: [0,1,0])
                actor.renderActor(renderEncoder)
                i++
            }
        }
    }
    
    
    
    
    
    func renderLight(renderEncoder:MTLRenderCommandEncoder){
        renderEncoder.label = "Light"

        
        
        if m_lights.count == 0{
            return
        }else{
            renderEncoder.setVertexBuffer(m_scene.m_camera.projectionBuffer(), offset: 0, atIndex: ShaderIndex.Projection.rawValue)
            renderEncoder.setVertexBuffer(m_scene.m_camera.viewBuffer(), offset: 0, atIndex: ShaderIndex.View.rawValue)
            
            renderEncoder.setFragmentBuffer(m_scene.m_camera.viewBuffer(), offset: 0, atIndex: 1)

            for light in m_lights{
                //stencil
                renderEncoder.setCullMode(MTLCullMode.Front)
                renderEncoder.setStencilReferenceValue(128)

                renderEncoder.setRenderPipelineState(m_lightMaskPipelineState)
                renderEncoder.setDepthStencilState(m_lightMaskDepthStencilState)
                light.renderActor(renderEncoder)
                
                let clip = (light.m_lightInfo[2] + (6 * circumscribe / inscribe)) < 0.1
                if clip{
                    renderEncoder.setDepthStencilState(m_lightColorDepthStencilStateNoDepth)
                    renderEncoder.setCullMode(.Front)
                }else{
                    renderEncoder.setDepthStencilState(m_lightColorDepthStencilState)
                    renderEncoder.setCullMode(.Back)
                }

                
                
                //renderEncoder.setCullMode(.Back)
                renderEncoder.setStencilReferenceValue(128)

                renderEncoder.setRenderPipelineState(m_lightColorPipelineState)
                //renderEncoder.setDepthStencilState(m_lightColorDepthStencilState)
                light.renderActor(renderEncoder)

                //renderEncoder.popDebugGroup()
                
            }

        }
        
    }

    func composition(renderEncoder:MTLRenderCommandEncoder){
        //let normalMatrix:float3x4 = float3x4(m_scene.m_camera.m_projectionMatrix[0],)
        renderEncoder.setCullMode(.None)
        renderEncoder.setRenderPipelineState(m_compositionPipelineState)
        renderEncoder.setDepthStencilState(m_compositionDepthStencilState)
        renderEncoder.setFragmentBytes(m_scene.m_sun, length: sizeofValue(m_scene.m_sun[0]) * m_scene.m_sun.count, atIndex: 0)
        renderEncoder.setFragmentBuffer(m_scene.m_camera.viewBuffer(), offset: 0, atIndex: 1)
        renderEncoder.setVertexBytes(screen_vertexOnly, length: sizeofValue(screen_vertexOnly[0]) * screen_vertexOnly.count, atIndex: 0)
        //renderEncoder.setVertexBuffer(m_compositionVertexBuffer, offset: 0, atIndex: 0)
        renderEncoder.drawPrimitives(MTLPrimitiveType.Triangle, vertexStart: 0, vertexCount: 6)
    }
    
    
    /*func renderSceneToScreen(renderEncoder:MTLRenderCommandEncoder){
        renderEncoder.setRenderPipelineState(m_renderToScreenPipelineState)
        renderEncoder.setDepthStencilState(m_renderToScreenDepthStencilState)
        renderEncoder.setFragmentTexture(m_gBufferTexture, atIndex: 0)
        //renderEncoder.setVertexBuffer(m_renderToScreenBuffer, offset: 0, atIndex: 0)
        renderEncoder.setVertexBytes(screen_vertexOnly, length: sizeofValue(screen_vertexOnly[0]) * screen_vertexOnly.count, atIndex: 0)
        renderEncoder.setVertexBytes(screen_textureCoord, length: sizeofValue(screen_textureCoord[0]) * screen_textureCoord.count, atIndex: 1)
        renderEncoder.drawPrimitives(MTLPrimitiveType.Triangle, vertexStart: 0, vertexCount: 6)

    }*/


    
    
    
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        m_changeSize = true
        m_size = size
        m_scene.m_camera.changeSize()
    }

}