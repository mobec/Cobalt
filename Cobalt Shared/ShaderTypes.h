//
//  ShaderTypes.h
//  Cobalt Shared
//
//  Created by Mo Becher on 19.06.18.
//  Copyright © 2018 Mo Becher. All rights reserved.
//

//
//  Header containing types and enum constants shared between Metal shaders and Swift/ObjC source
//
#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>

typedef NS_ENUM(NSInteger, BufferIndex)
{
    BufferIndexMeshPositions,
    BufferIndexMeshGenerics,
    BufferIndexUniforms,
    BufferIndexSize
};

typedef NS_ENUM(NSInteger, VertexAttribute)
{
    VertexAttributePosition,
    VertexAttributeTexcoord,
};

typedef NS_ENUM(NSInteger, TextureIndex)
{
    TextureIndexAlbedo    = 0,
    TextureIndexNormalDepth,
    TextureIndexColorMap,
    TextureIndexSize
};

typedef struct
{
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 modelViewMatrix;
} Uniforms;

#endif /* ShaderTypes_h */

