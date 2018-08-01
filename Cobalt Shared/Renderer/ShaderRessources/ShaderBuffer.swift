//
//  ShaderBuffer.swift
//  Cobalt
//
//  Created by Mo Becher on 25.06.18.
//  Copyright © 2018 Mo Becher. All rights reserved.
//

import Metal
import MetalKit

protocol PShaderBuffer {
    var bufferIndex: BufferIndex { get }
    var bufferGPU: MTLBuffer { get }
    var offset: Int { get }
    func update()
}

class ShaderBuffer<T> : PShaderBuffer {
    var bufferGPU : MTLBuffer
    var offset = 0
    var index = 0
    // The 256 byte aligned size of our uniform structure
    fileprivate let alignedSize = (MemoryLayout<T>.size & ~0xFF) + 0x100
    var ressourceCPU: UnsafeMutablePointer<T>
    let maxBuffersInFlight = 3
    let bufferIndex: BufferIndex
    
    init?(context: Context, bufferIndex: BufferIndex, label: String){
        self.bufferIndex = bufferIndex
        let bufferSize = alignedSize * maxBuffersInFlight
        guard let buffer = context.device.makeBuffer(length: bufferSize, options: [MTLResourceOptions.storageModeShared]) else { return nil}
        self.bufferGPU = buffer
        self.bufferGPU.label = label
        self.ressourceCPU = UnsafeMutableRawPointer(bufferGPU.contents()).bindMemory(to: T.self, capacity: 1)
        
        context.register(buffer: self)
    }
    
    func update() {
        index = (index + 1) % maxBuffersInFlight
        offset = alignedSize * index
        self.ressourceCPU = UnsafeMutableRawPointer(bufferGPU.contents() + offset).bindMemory(to:T.self, capacity:1)
    }
    
    func set(value: T) {
        self.ressourceCPU[0] = value
    }
}
