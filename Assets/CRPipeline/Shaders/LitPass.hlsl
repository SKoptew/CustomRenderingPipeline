#ifndef _CRP_LIT_PASS_INCLUDED_
#define _CRP_LIT_PASS_INCLUDED_

#include "Assets/CRPipeline/ShaderLibrary/Common.hlsl"
#include "Assets/CRPipeline/ShaderLibrary/SurfaceData.hlsl"
#include "Assets/CRPipeline/ShaderLibrary/LightData.hlsl"
#include "Assets/CRPipeline/ShaderLibrary/Lighting.hlsl"

struct Attributes
{
    float3 positionOS : POSITION;
    float3 normalOS   : NORMAL;
    float2 UV         : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionOS : SV_POSITION;
    float3 normalWS   : TEXCOORD0;
    float2 UV         : TEXCOORD1;
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

Varyings LitPassVertex(Attributes IN)
{
    Varyings OUT;
    
    UNITY_SETUP_INSTANCE_ID(IN);
    UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
    
    float3 positionWS = TransformObjectToWorld(IN.positionOS);    
    OUT.positionOS = TransformWorldToHClip(positionWS);
    OUT.normalWS   = TransformObjectToWorldNormal(IN.normalOS);
    
    float4 uv_ST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _ColorTexture_ST);
    OUT.UV = IN.UV * uv_ST.xy + uv_ST.zw;
    
    return OUT;    
}

float4 LitPassFragment(Varyings IN) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(IN);
    
    float4 baseColor = SAMPLE_TEXTURE2D(_ColorTexture, sampler_ColorTexture, IN.UV)
                     * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Color);
                     
#ifdef USE_ALPHA_CLIPPING
    clip(baseColor.a - UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff));
#endif
    
    SurfaceData surface;
    surface.normal = normalize(IN.normalWS);
    surface.color  = baseColor.rgb;
    surface.alpha  = baseColor.a;
    
    float3 color = GetLighting(surface);
    
    return float4(color, surface.alpha);
}

#endif