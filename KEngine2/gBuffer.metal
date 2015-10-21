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
    float linearDepth = (view * model * float4(float3(in[vid].position),1.0)).z;
    out.normal = view * model * float4(float3(in[vid].normal),0);
    out.normal.w = linearDepth;
    out.posWorld = model * float4(float3(in[vid].position),1.0);
    out.color = half3(in[vid].color);
    //out.linearDepth = (view.matrix * model.matrix * float4(float3(in[vid].pos),1.0)).z;
    //out.textCoord = float2(in[vid].textCoord);
    
    return out;
    
}


fragment GBufferOut gbufferFragment(GbufferInOut in [[stage_in]]){
    GBufferOut out;
        
    out.pos = in.posWorld;//color 2
    out.normal = in.normal;//color 1
    out.color = half4(in.color,1); //color 0
    out.light = float4(0,0,0,1);
    return out;
}
