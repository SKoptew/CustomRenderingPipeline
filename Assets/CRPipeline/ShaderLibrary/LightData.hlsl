#ifndef _CRP_LIGHT_DATA_INCLUDED_
#define _CRP_LIGHT_DATA_INCLUDED_

#define MAX_DIRECTIONAL_LIGHT_COUNT 4

CBUFFER_START(_CustomLight)
    int    _DirectionalLightCount;
    float3 _DirectionalLightColors[MAX_DIRECTIONAL_LIGHT_COUNT];
    float3 _DirectionalLightDirections[MAX_DIRECTIONAL_LIGHT_COUNT];
    float4 _DirectionalLightShadowData[MAX_DIRECTIONAL_LIGHT_COUNT]; // shadow strength + shadow atlas tile index
CBUFFER_END

struct LightData
{
    float3 color;
    float3 direction;
    float  attenuation; // from shadow
};

int GetDirectionalLightCount()
{
    return _DirectionalLightCount;
}

DirectionalShadowData GetDirectionalShadowData(int lightIndex, ShadowData shadowData)
{
    DirectionalShadowData data;
    data.strength  = _DirectionalLightShadowData[lightIndex].x * shadowData.mul;
    data.tileIndex = _DirectionalLightShadowData[lightIndex].y + shadowData.cascadeIndex;
    
    return data;
}

LightData GetDirectionalLight(int idx, float3 surfacePositionWS, ShadowData shadowData)
{
    LightData light;
    light.color     = _DirectionalLightColors[idx].rgb;
    light.direction = _DirectionalLightDirections[idx].xyz;
    
    DirectionalShadowData dirShadowData = GetDirectionalShadowData(idx, shadowData);
    light.attenuation = GetDirectionalShadowAttenuation(dirShadowData, surfacePositionWS);
    
        //light.attenuation = shadowData.cascadeIndex * 0.25 * shadowData.mul; // show cascades
    return light;
}

#endif