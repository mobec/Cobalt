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

class BaseRenderPass : RenderPass
{
    var view: MTKView
    var vertexShader: VertexShader?
    var fragmentShader: FragmentShader?
    var pipelineState : MTLRenderPipelineState
    var depthState: MTLDepthStencilState
    var shaderRessources: ShaderRessourceFactory

    init?(v: MTKView, shaderRessources: ShaderRessourceFactory)
    {
        guard let library = v.device!.makeDefaultLibrary() else { return nil }
        
        vertexShader = VertexShader(library: library, name: "vertexShader", usedBuffers: [BufferIndex.meshPositions, BufferIndex.meshGenerics, BufferIndex.uniforms], usedTextures: [])
        fragmentShader = FragmentShader(library: library, name: "fragmentShader", usedBuffers: [], usedTextures: [TextureIndex.color])
        
        view = v
        view.depthStencilPixelFormat = MTLPixelFormat.depth32Float_stencil8
        view.colorPixelFormat = MTLPixelFormat.bgra8Unorm_srgb
        view.sampleCount = 1 // disable multisampling
        
        guard let pipelineState = BaseRenderPass.buildPipelineState(vertexShader: self.vertexShader, fragmentShader: self.fragmentShader, device: self.view.device!) else {return nil}
        self.pipelineState = pipelineState
        
        let depthStateDesciptor = MTLDepthStencilDescriptor()
        depthStateDesciptor.depthCompareFunction = MTLCompareFunction.less
        depthStateDesciptor.isDepthWriteEnabled = true
        guard let state = self.view.device?.makeDepthStencilState(descriptor:depthStateDesciptor) else { return nil }
        depthState = state
        
        self.shaderRessources = shaderRessources
    }
    
    class func buildPipelineState(vertexShader: VertexShader?, fragmentShader: FragmentShader?, device: MTLDevice) -> MTLRenderPipelineState?
    {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "RenderPipeline"
        pipelineDescriptor.rasterSampleCount = 1; // disable multisampling
        pipelineDescriptor.vertexFunction = vertexShader?.vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentShader?.fragmentFunction
        pipelineDescriptor.vertexDescriptor = BaseRenderPass.buildMetalVertexDescriptor()
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm_srgb
        pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
        pipelineDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
        
        do {
            return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Unable to compile render pipeline state. Error info: \(error)")
            return nil
        }
    }
    
    class func buildMetalVertexDescriptor() -> MTLVertexDescriptor
    {
        // Creete a Metal vertex descriptor specifying how vertices will by laid out for input into our render
        //   pipeline and how we'll layout our Model IO vertices
        
        let mtlVertexDescriptor = MTLVertexDescriptor()
        
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].format = MTLVertexFormat.float3
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].offset = 0
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].bufferIndex = BufferIndex.meshPositions.rawValue
        
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].format = MTLVertexFormat.float2
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].offset = 0
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].bufferIndex = BufferIndex.meshGenerics.rawValue

        mtlVertexDescriptor.layouts[BufferIndex.meshPositions.rawValue].stride = 12
        mtlVertexDescriptor.layouts[BufferIndex.meshPositions.rawValue].stepRate = 1
        mtlVertexDescriptor.layouts[BufferIndex.meshPositions.rawValue].stepFunction = MTLVertexStepFunction.perVertex
        
        mtlVertexDescriptor.layouts[BufferIndex.meshGenerics.rawValue].stride = 8
        mtlVertexDescriptor.layouts[BufferIndex.meshGenerics.rawValue].stepRate = 1
        mtlVertexDescriptor.layouts[BufferIndex.meshGenerics.rawValue].stepFunction = MTLVertexStepFunction.perVertex
        
        return mtlVertexDescriptor
    }
    
    func getRenderPassDescriptor() -> MTLRenderPassDescriptor?
    {
        return view.currentRenderPassDescriptor
    }
    
    func draw(commandBuffer: MTLCommandBuffer, meshes: [MTKMesh])
    {
        /// Delay getting the currentRenderPassDescriptor until we absolutely need it to avoid
        ///   holding onto the drawable and blocking the display pipeline any longer than necessary
        let renderPassDescriptor = self.getRenderPassDescriptor()
        
        if let renderPassDescriptor = renderPassDescriptor, let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        {
            
            /// Final pass rendering code here
            renderEncoder.label = "Primary Render Encoder"
            
            renderEncoder.pushDebugGroup("Draw Box")
            
            renderEncoder.setCullMode(.back)
            
            renderEncoder.setFrontFacing(.counterClockwise)
            
            renderEncoder.setRenderPipelineState(self.pipelineState)
            
            renderEncoder.setDepthStencilState(self.depthState)
            
            // set vertex shader ressources
            if let vertexShader = self.vertexShader
            {
                for bufferIndex in vertexShader.usedBuffers
                {
                    if let buffer = shaderRessources.buffers[bufferIndex.rawValue]
                    {
                        renderEncoder.setVertexBuffer(buffer.bufferGPU, offset:buffer.offset, index: bufferIndex.rawValue)
                    }
                }
                
                for textureIndex in vertexShader.usedTextures
                {
                    if let texture = shaderRessources.textures[textureIndex.rawValue]
                    {
                        renderEncoder.setVertexTexture(texture.textureGPU, index: textureIndex.rawValue)
                    }
                }
            }
            
            // set fragment shader ressources
            if let fragmentShader = self.fragmentShader
            {
                for bufferIndex in fragmentShader.usedBuffers
                {
                    if let buffer = shaderRessources.buffers[bufferIndex.rawValue]
                    {
                        renderEncoder.setFragmentBuffer(buffer.bufferGPU, offset:buffer.offset, index: bufferIndex.rawValue)
                    }
                }
                
                for textureIndex in fragmentShader.usedTextures
                {
                    if let texture = shaderRessources.textures[textureIndex.rawValue]
                    {
                        renderEncoder.setFragmentTexture(texture.textureGPU, index: textureIndex.rawValue)
                    }
                }
            }
            
            // draw all meshes
            for mesh in meshes
            {
                for (index, element) in mesh.vertexDescriptor.layouts.enumerated() {
                    guard let layout = element as? MDLVertexBufferLayout else {
                        return
                    }
                    
                    if layout.stride != 0 {
                        let buffer = mesh.vertexBuffers[index]
                        renderEncoder.setVertexBuffer(buffer.buffer, offset:buffer.offset, index: index)
                    }
                }
                
                for submesh in mesh.submeshes {
                    renderEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                        indexCount: submesh.indexCount,
                                                        indexType: submesh.indexType,
                                                        indexBuffer: submesh.indexBuffer.buffer,
                                                        indexBufferOffset: submesh.indexBuffer.offset)
                    
                }
            }

            
            renderEncoder.popDebugGroup()
            
            renderEncoder.endEncoding()
            
            if let drawable = view.currentDrawable {
                commandBuffer.present(drawable)
            }
        }
        
        commandBuffer.commit()
    }
}
