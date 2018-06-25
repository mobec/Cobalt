//
//  RenderPass.swift
//  Cobalt
//
//  Created by Mo Becher on 19.06.18.
//  Copyright © 2018 Mo Becher. All rights reserved.
//

import Metal
import MetalKit

protocol RenderPass
{
    static func buildMetalVertexDescriptor() -> MTLVertexDescriptor //??
    func getRenderPassDescriptor() -> MTLRenderPassDescriptor?
}
