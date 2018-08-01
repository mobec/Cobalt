//
//  RenderTargetShaderTexture.swift
//  Cobalt
//
//  Created by Mo Becher on 30.06.18.
//  Copyright © 2018 Mo Becher. All rights reserved.
//

import Metal
import MetalKit

// TODO: update on view change
class RenderTargetShaderTexture : ShaderTexture
{
    init?(context: Context, textureIndex: TextureIndex, height: Int, width: Int, pixelFormat: MTLPixelFormat)
    {
        super.init(context: context, textureIndex: textureIndex)
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.height = height
        textureDescriptor.width = width
        textureDescriptor.usage.insert(MTLTextureUsage.renderTarget)
        textureDescriptor.storageMode = MTLStorageMode.private
        textureDescriptor.pixelFormat = pixelFormat
        
        guard let textureGPU = context.device.makeTexture(descriptor: textureDescriptor) else {return nil}
        self.textureGPU = textureGPU
    }
}
