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
    float4   _CascadeCullingSpheres[MAX_CASCADE_COUNT];  // cullingSphere.xyz, cullingSphere.w^2
    float4   _CascadeData[MAX_CASCADE_COUNT];            // 1/cullingSphere.w
    float4   _ShadowDistanceFade;                        // 1/maxShadowDistance; 1/distanceFadeRange; 1/cascadeFadeRange^2
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
    float normalBias;
};

float FadeShadow(float depth, float scale, float fade)
{
    return saturate((1.0 - depth*scale) * fade);
}


ShadowData GetShadowData(float3 positionWS, float depth)
{
    ShadowData data;
    data.mul = FadeShadow(depth, _ShadowDistanceFade.x, _ShadowDistanceFade.y); // fade - camera depth
    
    //-- select proper cascade
    int cascadeIdx = 0;
    for (; cascadeIdx < _CascadeCount; ++cascadeIdx)
    {
        float4 cullingSphere = _CascadeCullingSpheres[cascadeIdx];
        float distance2 = DistanceSquared(positionWS, cullingSphere.xyz);
        
        if (distance2 < cullingSphere.w)
        {
            data.cascadeIndex = cascadeIdx;
            
            if (cascadeIdx == _CascadeCount-1)
                data.mul *= FadeShadow(distance2, _CascadeData[cascadeIdx].x, _ShadowDistanceFade.z); // fade - distance^2 in last cascade
            
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

float GetDirectionalShadowAttenuation(DirectionalShadowData dirShadowData, ShadowData shadowData, SurfaceData surfaceWS)
{
    if (dirShadowData.strength <= 0.0)
        return 1.0;
        
    float3 normalBias = surfaceWS.normal * (dirShadowData.normalBias * _CascadeData[shadowData.cascadeIndex].y);
    
    float3 positionSTS = mul(
        _DirectionalShadowMatrices[dirShadowData.tileIndex], 
        float4(surfaceWS.position + normalBias, 1.0)).xyz;
        
    float shadowValue = SampleDirectionalShadowAtlas(positionSTS);
    return lerp(1.0, shadowValue, dirShadowData.strength);
}

#endif