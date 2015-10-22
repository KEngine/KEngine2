//
//  gBuffer.metal
//  KEngine2
//
//  Created by 哈哈 on 15/10/19.
//  Copyright © 2015年 哈哈. All rights reserved.
//

#include <metal_stdlib>
#include "shaderType.h"

using namespace metal;




vertex GbufferInOut gbufferVertex(const device VertexIn* in [[buffer(0)]],const device float4x4& projection [[buffer(1)]],const device float4x4& view [[buffer(2)]],const device float4x4& model [[buffer(3)]],unsigned int vid [[vertex_id]]){
    GbufferInOut out;
    
    
    out.pos = projection * view * model * float4(in[vid].position,1);
    out.normal = view * model * float4(float3(in[vid].normal),0);
    out.posWorld = model * float4(float3(in[vid].position),1.0);
    out.color = float3(in[vid].color);
    out.linearDepth = (view * model * float4(float3(in[vid].position),1.0)).z;
    
    return out;
    
}


fragment GBufferOut gbufferFragment(GbufferInOut in [[stage_in]],texture2d<float> actorTexture [[texture(0)]]){
    GBufferOut out;
        
    //out.pos = in.posWorld;//color 2
    out.normal.xyz = in.normal.xyz;//color 1
    out.depth = in.linearDepth;
    out.color = half4(half3(in.color),1); //color 0
    out.light = float4(0,0,0,1);
    return out;
}
