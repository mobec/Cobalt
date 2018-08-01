//
//  ColorRenderPass.swift
//  Cobalt
//
//  Created by Mo Becher on 26.06.18.
//  Copyright © 2018 Mo Becher. All rights reserved.
//

import Metal
import MetalKit

class GBufferRenderPass : RenderPass
{
    var albedoTarget: ShaderTexture?
    var normalDepthTarget: ShaderTexture?
    
    init?(context: Context, viewPortSize: CGSize)
    {
        super.init(context: context, label: "GBuffer Render Pass")
        self.drawableSizeWillChange(size: viewPortSize)
        
        //guard let library = context.device.makeDefaultLibrary() else { return nil }
        
        self.vertexShader = VertexShader(library: self.context.library, name: "gbuffer_vertex", usedBuffers: [BufferIndex.meshPositions, BufferIndex.meshGenerics, BufferIndex.uniforms], usedTextures: [])
        self.fragmentShader = FragmentShader(library: self.context.library, name: "gbuffer_fragment", usedBuffers: [], usedTextures: [TextureIndex.colorMap, TextureIndex.albedo, TextureIndex.normalDepth])
    }
    
    override func drawableSizeWillChange(size: CGSize)
    {
        self.albedoTarget = RenderTargetShaderTexture(context: self.context, textureIndex: TextureIndex.albedo, height: Int(size.height), width: Int(size.width), pixelFormat: MTLPixelFormat.bgra8Unorm_srgb)
        self.normalDepthTarget = RenderTargetShaderTexture(context: self.context, textureIndex: TextureIndex.normalDepth, height: Int(size.height), width: Int(size.width), pixelFormat: MTLPixelFormat.bgra8Unorm_srgb)
    }
    
    override func getDepthState() -> MTLDepthStencilState?
    {
        let depthStateDesciptor = MTLDepthStencilDescriptor()
        depthStateDesciptor.isDepthWriteEnabled = false
        return self.context.device.makeDepthStencilState(descriptor:depthStateDesciptor)
    }
    
    override func getRenderPassDescriptor() -> MTLRenderPassDescriptor?
    {
        let albedoAttachment = MTLRenderPassColorAttachmentDescriptor()
        //albedoAttachment.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)
        albedoAttachment.texture = self.albedoTarget?.textureGPU
        
        let normalDepthAttachment = MTLRenderPassColorAttachmentDescriptor()
        //normalDepthAttachment.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)
        normalDepthAttachment.texture = self.normalDepthTarget?.textureGPU
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[TextureIndex.albedo.rawValue] = albedoAttachment
        renderPassDescriptor.colorAttachments[TextureIndex.normalDepth.rawValue] = normalDepthAttachment
        return renderPassDescriptor
    }
    
    override func getPipelineState(vertexDescriptor: MTLVertexDescriptor) -> MTLRenderPipelineState?
    {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "GBuffer Render Pipeline"
        pipelineDescriptor.rasterSampleCount = 1
        pipelineDescriptor.vertexFunction = vertexShader?.vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentShader?.fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        guard let albedoPixelFormat = albedoTarget?.getPixelFormat() else { return nil }
        pipelineDescriptor.colorAttachments[TextureIndex.albedo.rawValue].pixelFormat = albedoPixelFormat
        guard let normalDepthPixelFormat = normalDepthTarget?.getPixelFormat() else { return nil }
        pipelineDescriptor.colorAttachments[TextureIndex.normalDepth.rawValue].pixelFormat = normalDepthPixelFormat
        
        do
        {
            return try context.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }
        catch
        {
            print("Unable to compile render pipeline state. Error info: \(error)")
            return nil
        }
    }
}
