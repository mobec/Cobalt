//
//  RenderPass.swift
//  Cobalt
//
//  Created by Mo Becher on 19.06.18.
//  Copyright © 2018 Mo Becher. All rights reserved.
//

import Metal
import MetalKit

class RenderPass
{
    var vertexShader: VertexShader?
    var fragmentShader: FragmentShader?
    var context: Context
    var label: String
    
    init?(context: Context, label: String)
    {
        self.context = context
        self.label = label
    }
    
    func drawableSizeWillChange(size: CGSize)
    {
        
    }
    
    func getRenderPassDescriptor() -> MTLRenderPassDescriptor?
    {
        return nil
    }
    
    func getPipelineState(vertexDescriptor: MTLVertexDescriptor) -> MTLRenderPipelineState?
    {
        return nil
    }
    
    func getDepthState() -> MTLDepthStencilState?
    {
        let depthStateDesciptor = MTLDepthStencilDescriptor()
        depthStateDesciptor.depthCompareFunction = MTLCompareFunction.less
        depthStateDesciptor.isDepthWriteEnabled = true
        return self.context.device.makeDepthStencilState(descriptor:depthStateDesciptor)
    }
    
    func getCurrentDrawable() -> MTLDrawable?
    {
        return nil
    }
    
    func draw(commandBuffer: MTLCommandBuffer, meshes: [MTKMesh], vertexDescriptor: MTLVertexDescriptor)
    {
        // Delay getting the currentRenderPassDescriptor until we absolutely need it to avoid
        //   holding onto the drawable and blocking the display pipeline any longer than necessary
        
        if let renderPassDescriptor = self.getRenderPassDescriptor(), // get hold of the renderpassdescriptor as late as possible to avoid blocking
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor),
            let pipelineState = getPipelineState(vertexDescriptor: vertexDescriptor),
            let depthState = getDepthState()
        {
            
            // Final pass rendering code here
            renderEncoder.label = self.label + "Render Encoder"
            
            renderEncoder.pushDebugGroup(self.label)
            
            renderEncoder.setCullMode(.back)
            
            renderEncoder.setFrontFacing(.counterClockwise)
            
            renderEncoder.setRenderPipelineState(pipelineState)
            
            renderEncoder.setDepthStencilState(depthState)
            
            // set vertex shader ressources
            if let vertexShader = self.vertexShader
            {
                for bufferIndex in vertexShader.usedBuffers
                {
                    if let buffer = context.buffers[bufferIndex.rawValue]
                    {
                        renderEncoder.setVertexBuffer(buffer.bufferGPU, offset:buffer.offset, index: bufferIndex.rawValue)
                    }
                }
                
                for textureIndex in vertexShader.usedTextures
                {
                    if let texture = context.textures[textureIndex.rawValue]
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
                    if let buffer = context.buffers[bufferIndex.rawValue]
                    {
                        renderEncoder.setFragmentBuffer(buffer.bufferGPU, offset:buffer.offset, index: bufferIndex.rawValue)
                    }
                }
                
                for textureIndex in fragmentShader.usedTextures
                {
                    if let texture = context.textures[textureIndex.rawValue]
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
            
            if let drawable = getCurrentDrawable()
            {
                commandBuffer.present(drawable)
            }
        }
    }
}
