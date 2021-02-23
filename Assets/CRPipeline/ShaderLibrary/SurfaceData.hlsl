#ifndef _CRP_SURFACE_DATA_INCLUDED_
#define _CRP_SURFACE_DATA_INCLUDED_

struct SurfaceData
{
    float3 normal;
    float3 viewDirection;
    float3 color;
    float  alpha;
    float  metallic;
    float  smoothness;
};

#endif