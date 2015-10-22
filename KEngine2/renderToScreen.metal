//
//  renderToScreen.metal
//  KEngine2
//
//  Created by 哈哈 on 15/10/21.
//  Copyright © 2015年 哈哈. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
struct screenInOut{
    float4 pos [[position]];
    float2 textureCoord;
};

vertex screenInOut renderToScreenVertex(constant packed_float3* pos [[buffer(0)]],constant packed_float2* textureCoord [[buffer(1)]],unsigned int vid [[vertex_id]]){
    screenInOut out;
    out.pos = float4(float3(pos[vid]),1);
    out.textureCoord = float2(textureCoord[vid]);
    return out;
    //return float4(pos[vid],1);
}


fragment half4 renderToScreenFragment(screenInOut in [[stage_in]],texture2d<half> gbuffer [[texture(0)]]){
    constexpr sampler defaultSampler;
    half4 color = gbuffer.sample(defaultSampler,in.textureCoord);
    return color;
    
}
