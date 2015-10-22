//
//  Light.metal
//  KEngine
//
//  Created by 哈哈 on 15/9/24.
//  Copyright © 2015年 哈哈. All rights reserved.
//

#include <metal_stdlib>
#include "shaderType.h"
using namespace metal;

struct LightInOut{
    float4 pos [[position]];
    float3 v_view;
    
    //float4 color;
};
struct LightVertex{
    packed_float3 pos;
    //packed_float3 normal;
    //packed_float2 texturecoord;
};


vertex LightInOut lightVertex(const device LightVertex* in [[buffer(0)]],const device float4x4& camera [[buffer(1)]],const device float4x4& view [[buffer(2)]],const device float4x4& model [[buffer(3)]],unsigned int vid [[vertex_id]]){
    LightInOut out;
    out.v_view = (view * model * float4(float3(in[vid].pos),1.0)).xyz;
    out.pos = camera * view * model * float4(float3(in[vid].pos),1.0);
    //out.color = float4(float3(lightInfo.color),1.0);
    
    return out;
}

fragment GBufferOut lightFragment(LightInOut in [[stage_in]],GBufferOut gbuffer,const device LightUniform& lightInfo [[buffer(4)]]){
    //gbuffer.light = float4(0,0,1,1);
    float3 n_s = gbuffer.normal.rgb;
    float scene_z = gbuffer.depth;
    float3 n = n_s * 2.0 - 1.0;
    float3 v = in.v_view * (scene_z / in.v_view.z);
    
    float3 l = in.v_view.xyz - v;
    
    
    
    float n_ls = dot(n, n);
    float v_ls = dot(v, v);
    float l_ls = dot(l, l);
    float3 h = (l * rsqrt(l_ls / v_ls) - v);
    float h_ls = dot(h, h);
    float nl = dot(n, l) * rsqrt(n_ls * l_ls);
    float nh = dot(n, h) * rsqrt(n_ls * h_ls);
    float d_atten = sqrt(l_ls);
    float atten = fmax(1.0 - d_atten / 6, 0.0);
    float diffuse = fmax(nl, 0.0) * atten;
    
    float4 light = gbuffer.light;
    light.rgb += float3(lightInfo.color)* diffuse;
    light.a += pow(fmax(nh, 0.0), 32.0) * step(0.0, nl) * atten * 1.0001;
    
    GBufferOut output;
    output.color = gbuffer.color;
    output.normal = gbuffer.normal;
    output.depth = gbuffer.depth;
    output.light = light;
    
    return output;
    
    //return out;
    
}


