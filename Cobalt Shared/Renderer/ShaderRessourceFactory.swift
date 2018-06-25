//
//  ShaderRessourceFactory.swift
//  Cobalt
//
//  Created by Mo Becher on 25.06.18.
//  Copyright © 2018 Mo Becher. All rights reserved.
//

import Metal

class ShaderRessourceFactory
{
    let device: MTLDevice
    var buffers = [PShaderBuffer?](repeating: nil, count: BufferIndex.size.rawValue)
    var textures = [PShaderTexture?](repeating: nil, count: TextureIndex.size.rawValue)
    
    init(device: MTLDevice)
    {
        self.device = device
    }
    
    // for correct deallocation of the shader ressources only hold weak references to the buffers
    func makeShaderBuffer<T>(label: String, bufferIndex: BufferIndex) -> ShaderBuffer<T>?
    {
        self.buffers[bufferIndex.rawValue] = ShaderBuffer<T>(device: self.device, label: label)
        return self.buffers[bufferIndex.rawValue] as! ShaderBuffer<T>?
    }
    
    func getShaderBuffer<T>(bufferIndex: BufferIndex) -> ShaderBuffer<T>?
    {
        return self.buffers[bufferIndex.rawValue] as! ShaderBuffer<T>?
    }
    
    func makeShaderTexture(name: String, textureIndex: TextureIndex) -> ShaderTexture?
    {
        self.textures[textureIndex.rawValue] = ShaderTexture(device: self.device, textureName: name)
        return self.textures[textureIndex.rawValue] as! ShaderTexture?
    }
    
    func getShaderTexture(textureIndex: TextureIndex) -> ShaderTexture?
    {
        return self.textures[textureIndex.rawValue] as! ShaderTexture?
    }
}
