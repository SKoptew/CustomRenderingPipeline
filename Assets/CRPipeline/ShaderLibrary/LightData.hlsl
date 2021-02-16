#ifndef _CRP_LIGHT_DATA_INCLUDED_
#define _CRP_LIGHT_DATA_INCLUDED_

#define MAX_DIRECTIONAL_LIGHT_COUNT 4

CBUFFER_START(_CustomLight)
    int    _DirectionalLightCount;
    float3 _DirectionalLightColors[MAX_DIRECTIONAL_LIGHT_COUNT];
    float3 _DirectionalLightDirections[MAX_DIRECTIONAL_LIGHT_COUNT];
CBUFFER_END

struct LightData
{
    float3 color;
    float3 direction;
};

int GetDirectionalLightCount()
{
    return _DirectionalLightCount;
}

LightData GetDirectionalLight(int idx)
{
    LightData light;
    light.color     = _DirectionalLightColors[idx].rgb;
    light.direction = _DirectionalLightDirections[idx].xyz;
    
    return light;
}

#endif