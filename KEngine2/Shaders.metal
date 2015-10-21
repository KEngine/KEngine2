//
//  Shaders.metal
//  KTerrain
//
//  Created by 哈哈 on 15/10/19.
//  Copyright (c) 2015年 哈哈. All rights reserved.
//

#include <metal_stdlib>
#include "shaderType.h"
using namespace metal;



vertex VertexInOut passThroughVertex(uint vid [[ vertex_id ]],
                                     const device VertexIn* in  [[ buffer(0)]],const device float4x4& projection [[buffer(1)]],const device float4x4& view [[buffer(2)]],const device float4x4& model [[buffer(3)]])
{
    VertexInOut outVertex;
    
    outVertex.position = projection * view * model * float4(in[vid].position,1);
    outVertex.color = float4(in[vid].color,1);
    return outVertex;
};

fragment half4 passThroughFragment(VertexInOut inFrag [[stage_in]])
{
    return half4(inFrag.color);
};