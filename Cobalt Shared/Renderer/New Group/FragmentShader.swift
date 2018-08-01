//
//  FragmentShader.swift
//  Cobalt
//
//  Created by Mo Becher on 24.06.18.
//  Copyright © 2018 Mo Becher. All rights reserved.
//

import Metal
import MetalKit

// MaterialShaders depend on the material beeing used and therefore must be compiled for each material. They do not depend on the mesh
class FragmentShader : Shader {
    let fragmentFunction: MTLFunction!
    var usedBuffers: [BufferIndex]
    var usedTextures: [TextureIndex]
    
    init?(library: MTLLibrary, name: String, usedBuffers: [BufferIndex] = [], usedTextures: [TextureIndex] = [])
    {
        fragmentFunction = library.makeFunction(name: name)
        self.usedBuffers = usedBuffers
        self.usedTextures = usedTextures
    }
}
