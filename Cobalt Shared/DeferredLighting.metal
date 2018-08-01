//
//  DeferredLighting.metal
//  Cobalt
//
//  Created by Mo Becher on 31.07.18.
//  Copyright © 2018 Mo Becher. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"
#import "ShaderCommon.h"

using namespace metal;

struct Vertex
{
    float3 position [[attribute(VertexAttributePosition)]];
    float2 texCoord [[attribute(VertexAttributeTexcoord)]];
};

struct VertexOut
{
    float4 position [[position]];
};

vertex VertexOut deferred_vertex(Vertex in [[stage_in]],
                                 constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]])
{
    VertexOut out;
    
    float4 position = float4(in.position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    
    return out;
}

fragment float4 deferred_fragment(VertexOut in [[stage_in]],
                                  constant Uniforms& uniforms [[buffer(BufferIndexUniforms)]],
                                  texture2d<float, access::read> albedo [[texture(TextureIndexAlbedo)]],
                                  texture2d<float> normalDepth [[texture(TextureIndexNormalDepth)]])
{
    uint2 position = uint2(in.position.xy);
    return albedo.read(position.xy);
}
