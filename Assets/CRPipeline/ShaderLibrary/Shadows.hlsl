#ifndef _CRP_SHADOWS_INCLUDED_
#define _CRP_SHADOWS_INCLUDED_

#define MAX_DIRECTIONAL_SHADOW_COUNT 4
#define MAX_CASCADE_COUNT 4

TEXTURE2D_SHADOW(_DirectionalShadowAtlas);

#define SHADOW_SAMPLER sampler_linear_clamp_compare
SAMPLER_CMP(SHADOW_SAMPLER); // SamplerComparisonState sampler_linear_clamp_compare;

CBUFFER_START(_CustomShadows)
    float4x4 _DirectionalShadowMatrices[MAX_DIRECTIONAL_SHADOW_COUNT * MAX_CASCADE_COUNT];
    int      _CascadeCount;
    float4   _CascadeCullingSpheres[MAX_CASCADE_COUNT];
    float4   _ShadowDistanceFade; // 1/maxShadowDistance; 1/fadeRange
CBUFFER_END

struct ShadowData // per-fragment
{
    int   cascadeIndex;
    float mul; // to cull shadow if fragment is out of shadow distance (view-space) or out of cascade culling spheres (world-space)
};

struct DirectionalShadowData // per-light
{
    float strength;
    int   tileIndex;
};

float FadeShadowFromDepth(float depth, float scale, float fade)
{
    return saturate((1.0 - depth*scale) * fade);
}


ShadowData GetShadowData(float3 positionWS, float depth)
{
    ShadowData data;
    data.mul = FadeShadowFromDepth(depth, _ShadowDistanceFade.x, _ShadowDistanceFade.y);
    
    //-- select proper cascade
    int cascadeIdx;
    for (cascadeIdx = 0; cascadeIdx < _CascadeCount; ++cascadeIdx)
    {
        float4 cullingSphere = _CascadeCullingSpheres[cascadeIdx];
        float distance2 = DistanceSquared(positionWS, cullingSphere.xyz);
        
        if (distance2 < cullingSphere.w)
        {
            data.cascadeIndex = cascadeIdx;
            break;
        }
    }
    
    if (cascadeIdx == _CascadeCount) // fragment positionWS out of max shadow distance
    {
        data.cascadeIndex = _CascadeCount-1;
        data.mul = 0.0;
    }
    
    return data;
}

float SampleDirectionalShadowAtlas(float3 positionSTS)
{
    return SAMPLE_TEXTURE2D_SHADOW(_DirectionalShadowAtlas, SHADOW_SAMPLER, positionSTS);
}

float GetDirectionalShadowAttenuation(DirectionalShadowData data, float3 positionWS)
{
    if (data.strength <= 0.0)
        return 1.0;

    float3 positionSTS = mul(_DirectionalShadowMatrices[data.tileIndex], float4(positionWS, 1.0)).xyz;    
    float shadowValue = SampleDirectionalShadowAtlas(positionSTS);
    return lerp(1.0, shadowValue, data.strength);
}

#endif