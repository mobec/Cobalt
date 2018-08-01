//
//  GBuffer.metal
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

typedef struct
{
    float3 position [[attribute(VertexAttributePosition)]];
    float2 texCoord [[attribute(VertexAttributeTexcoord)]];
} Vertex;

typedef struct
{
    float4 position [[position]];
    float2 texCoord;
} ColorInOut;

vertex ColorInOut gbuffer_vertex(Vertex in [[stage_in]], constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]])
{
    ColorInOut out;
    
    float4 position = float4(in.position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    out.texCoord = in.texCoord;
    
    return out;
}

fragment GBufferData gbuffer_fragment(ColorInOut in [[stage_in]],
                               constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]],
                               texture2d<half> colorMap     [[ texture(TextureIndexColorMap) ]])
{
    GBufferData out;
    
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);
    
    half4 colorSample = colorMap.sample(colorSampler, in.texCoord.xy);
    
    out.albedo = colorSample;
    out.normalDepth = half4(0.0, 1.0, 0.0, 0.0);
    return out;
}
