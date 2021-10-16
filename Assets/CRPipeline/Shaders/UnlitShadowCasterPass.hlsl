#ifndef _CRP_UNLIT_SHADOWCASTER_PASS_INCLUDED_
#define _CRP_UNLIT_SHADOWCASTER_PASS_INCLUDED_

#include "Assets/CRPipeline/ShaderLibrary/Common.hlsl"

struct Attributes
{
    float3 positionOS : POSITION;
    float2 UV         : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float2 UV         : TEXCOORD2;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};
//---------------------------------------------------------------------------------------

#include "UnlitInput.hlsl"
#include "ShadowCasterPassCommon.hlsl"

#endif