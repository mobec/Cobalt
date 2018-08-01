//
//  RessourceShaderTexture.swift
//  Cobalt
//
//  Created by Mo Becher on 31.07.18.
//  Copyright © 2018 Mo Becher. All rights reserved.
//

import Metal
import MetalKit

class RessourceShaderTexture : ShaderTexture
{
    init?(context: Context, textureIndex: TextureIndex, name: String)
    {
        super.init(context: context, textureIndex: textureIndex)
        
        let textureLoader = MTKTextureLoader(device: context.device)
        let textureLoaderOptions = [
            MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue ),
            MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue )
        ]
        do {
            self.textureGPU = try textureLoader.newTexture(name: name, scaleFactor: 1.0, bundle: nil, options: textureLoaderOptions)
        } catch {
            print("Unable to load texture. Error info: \(error)")
            return nil
        }
    }
}
