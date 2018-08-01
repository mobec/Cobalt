//
//  ShaderCommon.h
//  Cobalt
//
//  Created by Mo Becher on 31.07.18.
//  Copyright © 2018 Mo Becher. All rights reserved.
//

#ifndef ShaderCommon_h
#define ShaderCommon_h

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct GBufferData
{
    half4 albedo [[color(TextureIndexAlbedo)]];
    half4 normalDepth [[color(TextureIndexNormalDepth)]];
};

#endif /* ShaderCommon_h */
