#ifndef _CRP_LIGHTING_INCLUDED_
#define _CRP_LIGHTING_INCLUDED_

float3 IncomingLight(SurfaceData surface, LightData light)
{
    return saturate(dot(surface.normal, light.direction)) * light.color;
}

float3 GetLighting(SurfaceData surface, BRDFData brdf, LightData light)
{
    return DirectBRDF(surface, brdf, light) * IncomingLight(surface, light) * light.attenuation;
}

float3 GetLighting(SurfaceData surfaceWS, BRDFData brdf)
{
    float3 color = 0.0;
    ShadowData shadowData = GetShadowData(surfaceWS.position, surfaceWS.depth);
    
    const int dirLightCount = GetDirectionalLightCount();
    for (int i = 0; i < dirLightCount; ++i)
    {
        LightData light = GetDirectionalLight(i, surfaceWS, shadowData);
        color += GetLighting(surfaceWS, brdf, light);
    }
    
    return color;
}

#endif