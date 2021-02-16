#ifndef _CRP_LIGHTING_INCLUDED_
#define _CRP_LIGHTING_INCLUDED_

float3 IncomingLight(Surface surface, Light light)
{
    return saturate(dot(surface.normal, light.direction)) * light.color;
}

float3 GetLighting(Surface surface)
{
    float3 color = 0.0;
    
    const int dirLightCount = GetDirectionalLightCount();
    for (int i = 0; i < dirLightCount; ++i)
    {
        color += IncomingLight(surface, GetDirectionalLight(i));
    }
    
    color *= surface.color;
    return color;
}

#endif