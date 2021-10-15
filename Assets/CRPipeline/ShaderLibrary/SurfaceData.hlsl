#ifndef _CRP_SURFACE_DATA_INCLUDED_
#define _CRP_SURFACE_DATA_INCLUDED_

struct SurfaceData
{
    float3 position;
    float3 normal;
    float3 viewDirection;
    float  depth;
    float3 color;
    float  alpha;
    float  metallic;
    float  smoothness;
    float  dither; // used for _CASCADE_BLEND_DITHER
};

#endif