//
//  BaseRenderPass.swift
//  Cobalt
//
//  Created by Mo Becher on 24.06.18.
//  Copyright © 2018 Mo Becher. All rights reserved.
//

// BaseRenderPass is the last pass in the pipeline that renders to the MTKView
import Metal
import MetalKit

// BaseRenderPass is the last pass, drawing directly to the view
class BaseRenderPass : RenderPass
{
    var view: MTKView

    init?(context: Context, v: MTKView)
    {
        view = v
        view.depthStencilPixelFormat = MTLPixelFormat.depth32Float_stencil8
        view.colorPixelFormat = MTLPixelFormat.bgra8Unorm_srgb
        view.sampleCount = 1 // disable multisampling
        
        super.init(context: context, label: "Base Render Pass")
        
        guard let library = v.device!.makeDefaultLibrary() else { return nil }
        
        self.vertexShader = VertexShader(library: library, name: "vertexShader", usedBuffers: [BufferIndex.meshPositions, BufferIndex.meshGenerics, BufferIndex.uniforms], usedTextures: [])
        self.fragmentShader = FragmentShader(library: library, name: "fragmentShader", usedBuffers: [], usedTextures: [TextureIndex.colorMap])
    }
    
    override func getRenderPassDescriptor() -> MTLRenderPassDescriptor?
    {
        return view.currentRenderPassDescriptor
    }
    
    override func getPipelineState(vertexDescriptor: MTLVertexDescriptor) -> MTLRenderPipelineState?
    {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "RenderPipeline"
        pipelineDescriptor.rasterSampleCount = 1 // disable multisampling
        pipelineDescriptor.vertexFunction = self.vertexShader?.vertexFunction
        pipelineDescriptor.fragmentFunction = self.fragmentShader?.fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm_srgb
        pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
        pipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
        
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
