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
    var textureGPU: MTLTexture { get }
}

class ShaderTexture : PShaderTexture {
    var textureGPU: MTLTexture
    let device: MTLDevice
    
    // TODO: add more means to load texture. e.g. by URL
    init?(device: MTLDevice, textureName: String) {
        self.device = device
        let textureLoader = MTKTextureLoader(device: self.device)
        let textureLoaderOptions = [
            MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue ),
            MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue )
        ]
        do {
            self.textureGPU = try textureLoader.newTexture(name: textureName, scaleFactor: 1.0, bundle: nil, options: textureLoaderOptions)
        } catch {
            print("Unable to load texture. Error info: \(error)")
            return nil
        }
    }
}
