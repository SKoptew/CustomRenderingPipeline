#ifndef _CRP_LIGHT_INCLUDED_
#define _CRP_LIGHT_INCLUDED_

#define MAX_DIRECTIONAL_LIGHT_COUNT 4

CBUFFER_START(_CustomLight)
    int    _DirectionalLightCount;
    float3 _DirectionalLightColors[MAX_DIRECTIONAL_LIGHT_COUNT];
    float3 _DirectionalLightDirections[MAX_DIRECTIONAL_LIGHT_COUNT];
CBUFFER_END

struct Light
{
    float3 color;
    float3 direction;
};

int GetDirectionalLightCount()
{
    return _DirectionalLightCount;
}

Light GetDirectionalLight(int idx)
{
    Light light;
    light.color     = _DirectionalLightColors[idx].rgb;
    light.direction = _DirectionalLightDirections[idx].xyz;
    
    return light;
}

#endif