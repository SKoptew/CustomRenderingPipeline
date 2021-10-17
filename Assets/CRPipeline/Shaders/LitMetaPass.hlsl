#ifndef _CRP_LIT_META_PASS_INCLUDED_
#define _CRP_LIT_META_PASS_INCLUDED_

#include "Assets/CRPipeline/ShaderLibrary/Common.hlsl"
#include "Assets/CRPipeline/ShaderLibrary/SurfaceData.hlsl"
#include "Assets/CRPipeline/ShaderLibrary/Shadows.hlsl"
#include "Assets/CRPipeline/ShaderLibrary/LightData.hlsl"
#include "Assets/CRPipeline/ShaderLibrary/BRDF.hlsl"

struct Attributes
{
    float3 positionOS : POSITION;
    float2 UV         : TEXCOORD0;
    float2 lightmapUV : TEXCOORD1;
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float2 UV         : TEXCOORD1;
};

#include "LitInput.hlsl"

CBUFFER_START(UnityMetaPass)
    // x = use uv1 as raster position
    // y = use uv2 as raster position
    bool4 unity_MetaVertexControl;

    // x = return albedo
    // y = return normal
    bool4 unity_MetaFragmentControl;

    // Control which VisualizationMode we will
    // display in the editor
    int unity_VisualizationMode;
CBUFFER_END

float unity_OneOverOutputBoost;
float unity_MaxOutputValue;
//---------------------------------------------------------------------------------------

Varyings LitMetaPassVertex(Attributes IN)
{
    Varyings OUT;

    IN.positionOS.xy = IN.lightmapUV * unity_LightmapST.xy + unity_LightmapST.zw;
    IN.positionOS.z  = IN.positionOS.z > 0.0 ? FLT_MIN : 0.0;
    OUT.positionCS = TransformWorldToHClip(IN.positionOS);

    const float4 uv_ST = GetColorTexture_ST();
    OUT.UV = IN.UV * uv_ST.xy + uv_ST.zw;
    
    return OUT;    
}

float4 LitMetaPassFragment(Varyings IN) : SV_TARGET
{
    SurfaceData surface;
    ZERO_INITIALIZE(SurfaceData, surface);
    surface.color      = GetColor();
    surface.metallic   = GetMetallic();
    surface.smoothness = GetSmoothness();

    BRDFData brdfData = GetBRDFData(surface, false);

    float4 metaValue = 0.0;

    if (unity_MetaFragmentControl.x)
    {
        metaValue = float4(brdfData.diffuse, 1.0);
        //metaValue.rgb += brdfData.specular * brdfData.roughness * 0.5;
        metaValue.rgb = min(PositivePow(metaValue.rgb, unity_OneOverOutputBoost), unity_MaxOutputValue);
    }
    
    return metaValue;
}

#endif