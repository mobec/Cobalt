//
//  Renderer.swift
//  Cobalt Shared
//
//  Created by Mo Becher on 19.06.18.
//  Copyright © 2018 Mo Becher. All rights reserved.
//

// Our platform independent renderer class

import Metal
import MetalKit

enum RendererError: Error {
    case badVertexDescriptor
}

let maxBuffersInFlight = 1

class Renderer: NSObject, MTKViewDelegate {
    
    public let device: MTLDevice
    let commandQueue: MTLCommandQueue
    
    let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)
    
    weak var uniforms: ShaderBuffer<Uniforms>?
    weak var colorMap: ShaderTexture?
    
    var projectionMatrix: matrix_float4x4 = matrix_float4x4()
    var rotation: Float = 0
    var mesh: MTKMesh
    var renderPass: BaseRenderPass!
    var gbufferPass: GBufferRenderPass?
    var deferredLightingPass: DeferredLightingRenderPass?
    
    var context: Context
    
    init?(metalKitView: MTKView) {
        self.device = metalKitView.device!
        
        guard let context = Context(device: self.device) else { return nil }
        self.context = context

        guard let queue = self.device.makeCommandQueue() else { return nil }
        self.commandQueue = queue
        
        guard let uniforms : ShaderBuffer<Uniforms> = ShaderBuffer(context: self.context, bufferIndex: BufferIndex.uniforms, label: "Uniforms") else {return nil}
        self.uniforms = uniforms
        guard let colorMap = RessourceShaderTexture(context: self.context, textureIndex: TextureIndex.colorMap, name: "ColorMap") else { return nil }
        self.colorMap = colorMap
        
        renderPass = BaseRenderPass(context: self.context, v: metalKitView)
        self.gbufferPass = GBufferRenderPass(context: self.context, viewPortSize: metalKitView.drawableSize)
        self.deferredLightingPass = DeferredLightingRenderPass(context: self.context, view: metalKitView)
        
        let mtlVertexDescriptor = Renderer.buildMetalVertexDescriptor()
        
        do {
            mesh = try Renderer.buildMesh(device: device, mtlVertexDescriptor: mtlVertexDescriptor)
        } catch {
            print("Unable to build MetalKit Mesh. Error info: \(error)")
            return nil
        }
        
        super.init()
    }
    
    class func buildMesh(device: MTLDevice,
                         mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTKMesh {
        /// Create and condition mesh data to feed into a pipeline using the given vertex descriptor
        
        let metalAllocator = MTKMeshBufferAllocator(device: device)
        
        let mdlMesh = MDLMesh.newBox(withDimensions: float3(4, 4, 4),
                                     segments: uint3(2, 2, 2),
                                     geometryType: MDLGeometryType.triangles,
                                     inwardNormals:false,
                                     allocator: metalAllocator)
        
        let mdlVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(mtlVertexDescriptor)
        
        guard let attributes = mdlVertexDescriptor.attributes as? [MDLVertexAttribute] else {
            throw RendererError.badVertexDescriptor
        }
        attributes[VertexAttribute.position.rawValue].name = MDLVertexAttributePosition
        attributes[VertexAttribute.texcoord.rawValue].name = MDLVertexAttributeTextureCoordinate
        
        mdlMesh.vertexDescriptor = mdlVertexDescriptor
        
        return try MTKMesh(mesh:mdlMesh, device:device)
    }
    
    class func loadTexture(device: MTLDevice,
                           textureName: String) throws -> MTLTexture {
        /// Load texture data with optimal parameters for sampling
        
        let textureLoader = MTKTextureLoader(device: device)
        
        let textureLoaderOptions = [
            MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue)
        ]
        
        return try textureLoader.newTexture(name: textureName,
                                            scaleFactor: 1.0,
                                            bundle: nil,
                                            options: textureLoaderOptions)
        
    }
    
    private func updateDynamicBufferState() {
        /// Update the state of our uniform buffers before rendering
        self.uniforms!.update()
    }
    
    private func updateGameState() {
        /// Update any game state before rendering
        
        self.uniforms!.ressourceCPU[0].projectionMatrix = projectionMatrix
        
        let rotationAxis = float3(1, 1, 0)
        let modelMatrix = matrix4x4_rotation(radians: rotation, axis: rotationAxis)
        let viewMatrix = matrix4x4_translation(0.0, 0.0, -8.0)
        self.uniforms!.ressourceCPU[0].modelViewMatrix = simd_mul(viewMatrix, modelMatrix)
        rotation += 0.01
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
    
    func draw(in view: MTKView) {
        /// Per frame updates hare
        
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        if let commandBuffer = commandQueue.makeCommandBuffer()
        {
            let semaphore = inFlightSemaphore
            commandBuffer.addCompletedHandler { (_ commandBuffer)-> Swift.Void in
                semaphore.signal()
            }
            
            self.updateDynamicBufferState()
            
            self.updateGameState()
            
            gbufferPass?.draw(commandBuffer: commandBuffer, meshes: [mesh], vertexDescriptor: Renderer.buildMetalVertexDescriptor())
            deferredLightingPass?.draw(commandBuffer: commandBuffer, meshes: [mesh], vertexDescriptor: Renderer.buildMetalVertexDescriptor())
            //renderPass.draw(commandBuffer: commandBuffer, meshes: [mesh], vertexDescriptor: Renderer.buildMetalVertexDescriptor())
            
            commandBuffer.commit()
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        /// Respond to drawable size or orientation changes here
        
        let aspect = Float(size.width) / Float(size.height)
        projectionMatrix = matrix_perspective_right_hand(fovyRadians: radians_from_degrees(65), aspectRatio:aspect, nearZ: 0.1, farZ: 100.0)
    }
}
