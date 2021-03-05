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

DirectionalShadowData GetDirectionalShadowData(int lightIndex)
{
    DirectionalShadowData data;
    data.strength  = _DirectionalLightShadowData[lightIndex].x;
    data.tileIndex = _DirectionalLightShadowData[lightIndex].y;
    
    return data;
}

LightData GetDirectionalLight(int idx, float3 surfacePositionWS)
{
    LightData light;
    light.color     = _DirectionalLightColors[idx].rgb;
    light.direction = _DirectionalLightDirections[idx].xyz;
    
    DirectionalShadowData shadow = GetDirectionalShadowData(idx);
    light.attenuation = GetDirectionalShadowAttenuation(shadow, surfacePositionWS);
    
    return light;
}

#endif