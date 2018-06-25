//
//  VertexShader.swift
//  Cobalt
//
//  Created by Mo Becher on 24.06.18.
//  Copyright © 2018 Mo Becher. All rights reserved.
//

import Metal
import MetalKit

// MaterialVertexShaders depend on the material and vertex description beeing used and therefore must be compiled for each combination
class VertexShader : Shader {
    let vertexFunction: MTLFunction!
    var usedBuffers: [BufferIndex]
    var usedTextures: [TextureIndex]
    
    init?(library: MTLLibrary, name: String, usedBuffers: [BufferIndex] = [], usedTextures: [TextureIndex] = [])
    {
        vertexFunction = library.makeFunction(name: name)
        self.usedBuffers = usedBuffers
        self.usedTextures = usedTextures
    }
}
