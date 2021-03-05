#ifndef _CRP_SHADOWCASTER_PASS_INCLUDED_
#define _CRP_SHADOWCASTER_PASS_INCLUDED_

#include "Assets/CRPipeline/ShaderLibrary/Common.hlsl"

struct Attributes
{
    float3 positionOS : POSITION;
    float2 UV         : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float2 UV         : TEXCOORD2;
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

Varyings ShadowCasterPassVertex(Attributes IN)
{
    Varyings OUT;
    
    UNITY_SETUP_INSTANCE_ID(IN);
    UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
    
    float3 positionWS = TransformObjectToWorld(IN.positionOS);
    OUT.positionCS    = TransformWorldToHClip(positionWS);    
    
    float4 uv_ST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _ColorTexture_ST);
    OUT.UV = IN.UV * uv_ST.xy + uv_ST.zw;
    
    return OUT;    
}

void ShadowCasterPassFragment(Varyings IN)
{
#ifdef USE_ALPHA_CLIPPING
    UNITY_SETUP_INSTANCE_ID(IN);
    
    float4 baseColor = SAMPLE_TEXTURE2D(_ColorTexture, sampler_ColorTexture, IN.UV)
                     * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Color);
                     

    clip(baseColor.a - UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff));
#endif
}

#endif