//
//  DefferredShadingComposition.metal
//  KEngine
//
//  Created by 哈哈 on 15/9/5.
//  Copyright © 2015年 哈哈. All rights reserved.
//

//#include <metal_stdlib>
#include "shaderType.h"


using namespace metal;

//static constant float4 materialSpecular = float4(1,1,1,1);
//static constant float4 materialDiffuse = float4(0.4,0.4,0.4,1);



vertex float4 CompositonVertex(constant packed_float3* pos [[buffer(0)]],unsigned int vid [[vertex_id]]){
    return float4(pos[vid],1.0);
    //return out;
}


fragment float4 CompositionFragment(float4 in [[stage_in]],GBufferOut gBuffer,constant LightUniform&  sun [[buffer(0)]]){
    //half4 color = half4(0,0,0,1);
    
    float4 light = gBuffer.light;
    float3 diffuse = light.rgb;
    float3 specluar = light.aaa;
    
    //float3 n_s = gBuffer.normal.rgb;
    //float sun_atten = gBuffer.color.a;
    float sun_diffuse = float3(sun.color).x;//fmax(dot(n_s * 2.0 - 1.0,sun.pos),0.0) * sun_atten;
    
    diffuse += sun.color * sun_diffuse;
    diffuse *= float4(gBuffer.color).rgb;
    
    specluar *=gBuffer.normal.w;
    
    diffuse += diffuse;
    specluar += specluar;
    
    
    return float4(diffuse.xyz + specluar.xyz,1);
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    /*float3 vertex_cam = (view * gBuffer.pos).xyz;
    float3 normal_cam = gBuffer.normal.xyz;
    
    float4 ambient_color = float4(0.15,0.15,0.15,1);
    
    
    
   
    
    float4 diffuse_color = float4(0);
    float4 specluar_color = float4(0);
    
    
    //Compute The Sun (lights中的lights[0])
    float shine = 50;//lights[0].shine;
    float4 light_color = float4(float3(sun.color),1.0);
    float3 light_cam = (view * float4(float3(sun.pos),1.0)).xyz;
    
    float3 n = normalize(normal_cam);
    float3 l = normalize(light_cam);
    float n_dot_l = saturate(dot(n,l));
    diffuse_color += light_color * n_dot_l * float4(gBuffer.color);
    
    
    float3 e = normalize(light_cam  - vertex_cam);
    float3 r = -l + 2.0 * n_dot_l * n;
    float e_dot_r = saturate(dot(e,r));
    specluar_color += materialSpecular * light_color * pow(e_dot_r,shine);
    
    diffuse_color += gBuffer.light * materialDiffuse;
    specluar_color += gBuffer.light *materialSpecular;
    
    //color = half4(ambient_color + diffuse_color + specluar_color);
    //return color;
    //return half4(gBuffer.light);
    gBuffer.color = half4(ambient_color + diffuse_color + specluar_color);
    //gBuffer.color = half4(1,0,0,1);
    return gBuffer;*/
}












