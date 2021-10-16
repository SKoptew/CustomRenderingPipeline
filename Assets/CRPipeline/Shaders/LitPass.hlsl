#ifndef _CRP_LIT_PASS_INCLUDED_
#define _CRP_LIT_PASS_INCLUDED_

#include "Assets/CRPipeline/ShaderLibrary/Common.hlsl"
#include "Assets/CRPipeline/ShaderLibrary/SurfaceData.hlsl"
#include "Assets/CRPipeline/ShaderLibrary/Shadows.hlsl"
#include "Assets/CRPipeline/ShaderLibrary/LightData.hlsl"
#include "Assets/CRPipeline/ShaderLibrary/BRDF.hlsl"
#include "Assets/CRPipeline/ShaderLibrary/GI.hlsl"
#include "Assets/CRPipeline/ShaderLibrary/Lighting.hlsl"

struct Attributes
{
    float3 positionOS : POSITION;
    float3 normalOS   : NORMAL;
    float2 UV         : TEXCOORD0;
    GI_ATTRIBUTE_DATA
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float3 positionWS : TEXCOORD0;
    float3 normalWS   : TEXCOORD1;
    float2 UV         : TEXCOORD2;
    GI_VARYINGS_DATA
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

#include "LitInput.hlsl"
//---------------------------------------------------------------------------------------

Varyings LitPassVertex(Attributes IN)
{
    Varyings OUT;
    
    UNITY_SETUP_INSTANCE_ID(IN);
    UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
    TRANSFER_GI_DATA(IN, OUT);
    
    OUT.positionWS = TransformObjectToWorld(IN.positionOS);
    OUT.positionCS = TransformWorldToHClip(OUT.positionWS);    
    OUT.normalWS   = TransformObjectToWorldNormal(IN.normalOS);
    
    const float4 uv_ST = GetColorTexture_ST();
    OUT.UV = IN.UV * uv_ST.xy + uv_ST.zw;
    
    return OUT;    
}

float4 LitPassFragment(Varyings IN) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(IN);
    
    float4 baseColor = SAMPLE_TEXTURE2D(_ColorTexture, sampler_ColorTexture, IN.UV) * GetColor();
                     
#ifdef USE_ALPHA_CLIPPING
    clip(baseColor.a - GetCutoff());
#endif
    
    SurfaceData surface;
    surface.position      = IN.positionWS;
    surface.normal        = normalize(IN.normalWS);
    surface.viewDirection = normalize(_WorldSpaceCameraPos - IN.positionWS);
    surface.depth         = -TransformWorldToView(IN.positionWS).z;
    surface.color         = baseColor.rgb;
    surface.alpha         = baseColor.a;
    surface.metallic      = GetMetallic();
    surface.smoothness    = GetSmoothness(); // perceptual smoothness
#ifdef _CASCADE_BLEND_DITHER
    surface.dither        = InterleavedGradientNoise(IN.positionCS.xy, 0);
#endif
    
#ifdef PREMULTIPLY_ALPHA    
    BRDFData brdfData = GetBRDFData(surface, true);
#else
    BRDFData brdfData = GetBRDFData(surface, false);
#endif

    GI gi = GetGI(GI_FRAGMENT_DATA(IN));
    float3 color = GetLighting(surface, brdfData, gi);
    
    return float4(color, baseColor.a);
}

#endif