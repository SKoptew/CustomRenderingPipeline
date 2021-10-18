#ifndef _CRP_GI_INCLUDED
#define _CRP_GI_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"

TEXTURE2D(unity_Lightmap);
SAMPLER(samplerunity_Lightmap);

#ifdef LIGHTMAP_ON
    #define GI_ATTRIBUTE_DATA(N) float2 lightmapUV : TEXCOORD##N;
    #define GI_VARYINGS_DATA(N)  float2 lightmapUV : TEXCOORD##N;
    #define TRANSFER_GI_DATA(IN, OUT) OUT.lightmapUV = IN.lightmapUV * unity_LightmapST.xy + unity_LightmapST.zw;
    #define GI_FRAGMENT_DATA(IN) IN.lightmapUV
#else
    #define GI_ATTRIBUTE_DATA(N)
    #define GI_VARYINGS_DATA(N)
    #define TRANSFER_GI_DATA(IN, OUT)
    #define GI_FRAGMENT_DATA(IN) 0.0
#endif

float3 SampleLightMap(float2 lightmapUV)
{
    #ifdef LIGHTMAP_ON
        return SampleSingleLightmap(TEXTURE2D_ARGS(unity_Lightmap, samplerunity_Lightmap),
                                    lightmapUV,
                                    float4(1,1,0,0), // scale.xy, bias.zw
                                #if defined(UNITY_LIGHTMAP_FULL_HDR)
                                    false,          // encodedLightmap
                                #else
                                    true,
                                #endif
                                    real4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0, 0)); // decodeInstructions
    #else
        return 0.0;
    #endif
}
//------------------------------------------------------------------------------------------------------

float3 SampleLightProbes(SurfaceData surfaceWS)
{
    #ifdef LIGHTMAP_ON
        return 0.0;
    #else
        float4 SHCoefficients[7];
        SHCoefficients[0] = unity_SHAr;
        SHCoefficients[1] = unity_SHAg;
        SHCoefficients[2] = unity_SHAb;
        SHCoefficients[3] = unity_SHBr;
        SHCoefficients[4] = unity_SHBg;
        SHCoefficients[5] = unity_SHBb;
        SHCoefficients[6] = unity_SHC;

        return max(0.0, SampleSH9(SHCoefficients, surfaceWS.normal));
    #endif    
}

//------------------------------------------------------------------------------------------------------

struct GI
{
    float3 diffuse;
};

GI GetGI(float2 lightmapUV, SurfaceData surfaceWS)
{
    GI gi;

    #ifdef LIGHTMAP_ON
        gi.diffuse = SampleLightMap(lightmapUV); // baked indirect lighting
    #else
        gi.diffuse = SampleLightProbes(surfaceWS);
    #endif

    return gi;
}

#endif