#ifndef _CRP_UNLIT_PASS_INCLUDED_
#define _CRP_UNLIT_PASS_INCLUDED_

#include "Assets/CRPipeline/ShaderLibrary/Common.hlsl"

struct Attributes
{
    float3 positionOS : POSITION;
    float2 UV         : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionOS : SV_POSITION;
    float2 UV         : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};
//---------------------------------------------------------------------------------------

TEXTURE2D(_ColorTexture);
SAMPLER(sampler_ColorTexture);

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
    UNITY_DEFINE_INSTANCED_PROP(float4, _ColorTexture_ST)
    UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
    UNITY_DEFINE_INSTANCED_PROP(float,  _Cutoff)
UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
//---------------------------------------------------------------------------------------

Varyings UnlitPassVertex(Attributes Input)
{
    Varyings Output;
    
    UNITY_SETUP_INSTANCE_ID(Input);
    UNITY_TRANSFER_INSTANCE_ID(Input, Output);
    
    float3 positionWS = TransformObjectToWorld(Input.positionOS);    
    Output.positionOS = TransformWorldToHClip(positionWS);
    
    float4 uv_ST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _ColorTexture_ST);
    Output.UV = Input.UV * uv_ST.xy + uv_ST.zw;
    
    return Output;    
}

float4 UnlitPassFragment(Varyings Input) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(Input);
    
    float4 color = SAMPLE_TEXTURE2D(_ColorTexture, sampler_ColorTexture, Input.UV);
    color *= UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Color);
    
    #ifdef USE_ALPHA_CLIPPING
    clip(color.a - UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff));
    #endif
    
    return color;
}

#endif