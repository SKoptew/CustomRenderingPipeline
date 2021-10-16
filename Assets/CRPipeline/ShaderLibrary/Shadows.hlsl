#ifndef _CRP_SHADOWS_INCLUDED_
#define _CRP_SHADOWS_INCLUDED_

//--------------------------------------------------------------------------------------------------
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Shadow/ShadowSamplingTent.hlsl"

#if defined(_DIRECTIONAL_PCF3)
    #define DIRECTIONAL_FILTER_SAMPLES 4
    #define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_3x3
#elif defined(_DIRECTIONAL_PCF5)
    #define DIRECTIONAL_FILTER_SAMPLES 9
    #define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_5x5
#elif defined(_DIRECTIONAL_PCF7)
    #define DIRECTIONAL_FILTER_SAMPLES 16
    #define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_7x7
#endif

//--------------------------------------------------------------------------------------------------
#define MAX_DIRECTIONAL_SHADOW_COUNT 4
#define MAX_CASCADE_COUNT 4

TEXTURE2D_SHADOW(_DirectionalShadowAtlas);

#define SHADOW_SAMPLER sampler_linear_clamp_compare
SAMPLER_CMP(SHADOW_SAMPLER); // SamplerComparisonState sampler_linear_clamp_compare;

CBUFFER_START(_CustomShadows)
    float4x4 _DirectionalShadowMatrices[MAX_DIRECTIONAL_SHADOW_COUNT * MAX_CASCADE_COUNT];
    int      _CascadeCount;
    float4   _CascadeCullingSpheres[MAX_CASCADE_COUNT];  // cullingSphere.xyz, cullingSphere.w^2
    float4   _CascadeData[MAX_CASCADE_COUNT];            // 1/cullingSphere.w, filterSize*sqrt(2)
    float4   _ShadowAtlasSize;                           // atlasSize, 1/atlasSize == texel size
    float4   _ShadowDistanceFade;                        // 1/maxShadowDistance; 1/distanceFadeRange; 1/cascadeFadeRange^2
CBUFFER_END

struct ShadowData // per-fragment
{
    int   cascadeIndex;
    float cascadeBlend;
    float mul; // to cull shadow if fragment is out of shadow distance (view-space) or out of cascade culling spheres (world-space)
};

struct DirectionalShadowData // per-light
{
    float strength;
    int   tileIndex;
    float normalBias;
};

float FadeShadow(float depth, float scale, float fade)
{
    return saturate((1.0 - depth*scale) * fade);
}


ShadowData GetShadowData(float3 positionWS, float depth)
{
    ShadowData data;
    data.cascadeBlend = 1.0;
    data.mul          = 1.0;
    
    //-- select proper cascade
    int cascadeIdx = 0;
    for (; cascadeIdx < _CascadeCount; ++cascadeIdx)
    {
        float4 cullingSphere = _CascadeCullingSpheres[cascadeIdx];
        float distance2 = DistanceSquared(positionWS, cullingSphere.xyz);
        
        if (distance2 < cullingSphere.w)
        {
            // fade: distance^2 in the [i] cascade
            const float fade = FadeShadow(distance2, _CascadeData[cascadeIdx].x, _ShadowDistanceFade.z);
            
            data.cascadeIndex = cascadeIdx;
            
            if (cascadeIdx == _CascadeCount-1)
                data.mul = fade; // if last cascade, fade entire shadow value
            else
                data.cascadeBlend = fade;
            
            break;
        }
    }
    
    if (cascadeIdx == _CascadeCount) // fragment positionWS out of max shadow distance
    {
        data.cascadeIndex = _CascadeCount-1;
        data.mul = 0.0;
    }
    else
    {        
        data.mul *= FadeShadow(depth, _ShadowDistanceFade.x, _ShadowDistanceFade.y); // fade: camera depth
    }
    
    return data;
}

float SampleDirectionalShadowAtlas(float3 positionSTS)
{
    return SAMPLE_TEXTURE2D_SHADOW(_DirectionalShadowAtlas, SHADOW_SAMPLER, positionSTS);
}

float FilterDirectionalShadow(float3 positionSTS)
{
    #if defined(DIRECTIONAL_FILTER_SETUP)
    {
        float  weights  [DIRECTIONAL_FILTER_SAMPLES];
        float2 positions[DIRECTIONAL_FILTER_SAMPLES];
        float4 shadowMapTexture_TexelSize = _ShadowAtlasSize.yyxx;

        DIRECTIONAL_FILTER_SETUP(shadowMapTexture_TexelSize, positionSTS.xy, weights, positions);

        float shadowValue = 0.0;
        for (int i = 0; i < DIRECTIONAL_FILTER_SAMPLES; ++i)
        {
            shadowValue += weights[i] * SampleDirectionalShadowAtlas(float3(positions[i], positionSTS.z));
        }
        return shadowValue;
    }
    #else
    {
        return SampleDirectionalShadowAtlas(positionSTS); // sample once, without tent filtering
    }
    #endif    
}

float GetDirectionalShadowAttenuation(DirectionalShadowData dirShadowData, ShadowData shadowData, SurfaceData surfaceWS)
{
    #ifndef _RECEIVE_SHADOWS
        return 1.0;
    #endif
    
    if (dirShadowData.strength <= 0.0)
        return 1.0;

    #ifdef _CASCADE_BLEND_DITHER
    if (shadowData.cascadeBlend < surfaceWS.dither)
    {
        shadowData.cascadeIndex += 1;
        shadowData.cascadeIndex = min(shadowData.cascadeIndex, _CascadeCount-1);        
    }
    #endif
        
    float3 normalBias  = surfaceWS.normal * (dirShadowData.normalBias * _CascadeData[shadowData.cascadeIndex].y);    
    float3 positionSTS = mul(
        _DirectionalShadowMatrices[dirShadowData.tileIndex], 
        float4(surfaceWS.position + normalBias, 1.0)).xyz;
        
    float shadowValue = FilterDirectionalShadow(positionSTS);

    //-- blend with the next cascade value to get smoother cascades border
    #ifdef _CASCADE_BLEND_SOFT
    {
        normalBias  = surfaceWS.normal * (dirShadowData.normalBias * _CascadeData[shadowData.cascadeIndex + 1].y);
        positionSTS = mul(
            _DirectionalShadowMatrices[dirShadowData.tileIndex], 
            float4(surfaceWS.position + normalBias, 1.0)).xyz;

        shadowValue = lerp(FilterDirectionalShadow(positionSTS), shadowValue, shadowData.cascadeBlend);
    }
    #endif
    
    return lerp(1.0, shadowValue, dirShadowData.strength);
}

#endif