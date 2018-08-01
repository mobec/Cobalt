//
//  ShaderTexture.swift
//  Cobalt
//
//  Created by Mo Becher on 25.06.18.
//  Copyright © 2018 Mo Becher. All rights reserved.
//

import Metal
import MetalKit

protocol PShaderTexture {
    var textureGPU: MTLTexture? { get }
    var textureIndex: TextureIndex { get }
    func getPixelFormat() -> MTLPixelFormat?
}
class ShaderTexture : PShaderTexture {
    let textureIndex: TextureIndex
    var textureGPU: MTLTexture?
    
    init?(context: Context, textureIndex: TextureIndex)
    {
        self.textureIndex = textureIndex
        context.register(texture: self)
    }
    
    func getPixelFormat() -> MTLPixelFormat?
    {
        return textureGPU?.pixelFormat
    }
}
