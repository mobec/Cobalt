//
//  ShaderRessourceFactory.swift
//  Cobalt
//
//  Created by Mo Becher on 25.06.18.
//  Copyright © 2018 Mo Becher. All rights reserved.
//

import Metal

// Holds all buffers and textures used on a device in a use case (such as basic rendering)
class Context
{
    let device: MTLDevice
    let library: MTLLibrary
    var buffers = [PShaderBuffer?](repeating: nil, count: BufferIndex.size.rawValue)
    var textures = [PShaderTexture?](repeating: nil, count: TextureIndex.size.rawValue)

    init?(device: MTLDevice)
    {
        self.device = device
        guard let library = self.device.makeDefaultLibrary() else { return nil }
        self.library = library
    }
    
    // Shader Buffers
    func register(buffer: PShaderBuffer)
    {
        self.buffers[buffer.bufferIndex.rawValue] = buffer
    }
    
    func unregister(bufferIndex: BufferIndex)
    {
        self.buffers.remove(at: bufferIndex.rawValue)
    }
    
    // Shader Textures
    func register(texture: PShaderTexture)
    {
        self.textures[texture.textureIndex.rawValue] = texture
    }
    
    func unregister(textureIndex: TextureIndex)
    {
        self.textures.remove(at: textureIndex.rawValue)
    }
}
