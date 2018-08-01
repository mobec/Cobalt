//
//  DeferredLightingRenderPass.swift
//  Cobalt
//
//  Created by Mo Becher on 31.07.18.
//  Copyright © 2018 Mo Becher. All rights reserved.
//

import Metal
import MetalKit

class DeferredLightingRenderPass : RenderPass
{
    var view: MTKView
    
    init?(context: Context, view: MTKView)
    {
        self.view = view
        self.view.sampleCount = 1 // disable multisampling
        
        super.init(context: context, label: "Deferred Lighting Render Pass")
        
        self.vertexShader = VertexShader(library: self.context.library, name: "deferred_vertex", usedBuffers: [BufferIndex.meshPositions, BufferIndex.meshGenerics, BufferIndex.uniforms], usedTextures: [])
        self.fragmentShader = FragmentShader(library: self.context.library, name: "deferred_fragment", usedBuffers: [], usedTextures: [TextureIndex.albedo, TextureIndex.normalDepth])
    }
    
    override func getRenderPassDescriptor() -> MTLRenderPassDescriptor?
    {
        return view.currentRenderPassDescriptor
    }
    
    override func getPipelineState(vertexDescriptor: MTLVertexDescriptor) -> MTLRenderPipelineState?
    {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "DeferredRenderPipeline"
        pipelineDescriptor.rasterSampleCount = 1
        pipelineDescriptor.vertexFunction = self.vertexShader?.vertexFunction
        pipelineDescriptor.fragmentFunction = self.fragmentShader?.fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = self.view.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = self.view.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = self.view.depthStencilPixelFormat
        
        do
        {
            return try view.device!.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }
        catch
        {
            print("Unable to compile render pipeline state. Error info: \(error)")
            return nil
        }
    }
    
    override func getCurrentDrawable() -> MTLDrawable?
    {
        return self.view.currentDrawable
    }
}
