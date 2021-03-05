#ifndef _CRP_SHADOWS_INCLUDED_
#define _CRP_SHADOWS_INCLUDED_

#define MAX_DIRECTIONAL_SHADOW_COUNT 4

TEXTURE2D_SHADOW(_DirectionalShadowAtlas);

#define SHADOW_SAMPLER sampler_linear_clamp_compare
SAMPLER_CMP(SHADOW_SAMPLER); // SamplerComparisonState sampler_linear_clamp_compare;

CBUFFER_START(_CustomShadows)
    float4x4 _DirectionalShadowMatrices[MAX_DIRECTIONAL_SHADOW_COUNT];
CBUFFER_END

struct DirectionalShadowData
{
    float strength;
    int   tileIndex;
};

// sample from dir shadow atlas by known UV
float SampleDirectionalShadowAtlas(float3 positionSTS)
{
    return SAMPLE_TEXTURE2D_SHADOW(_DirectionalShadowAtlas, SHADOW_SAMPLER, positionSTS);
}

float GetDirectionalShadowAttenuation(DirectionalShadowData data, float3 positionWS)
{
    if (data.strength <= 0.0)
        return 1.0;

    float3 positionSTS = mul(_DirectionalShadowMatrices[data.tileIndex], float4(positionWS, 1.0)).xyz;
    //return positionSTS.x;
    
    float shadowValue = SampleDirectionalShadowAtlas(positionSTS);
    return shadowValue;
    //
    //return lerp(1.0, shadowValue, data.strength);
}

#endif