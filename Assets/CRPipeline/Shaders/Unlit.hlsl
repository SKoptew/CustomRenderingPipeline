#ifndef _CRP_UNLIT_PASS_INCLUDED_
#define _CRP_UNLIT_PASS_INCLUDED_

#include "Assets/CRPipeline/SHaderLibrary/Common.hlsl"

struct Attributes
{
    float3 positionOS : POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionOS : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
    UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

Varyings UnlitPassVertex(Attributes Input)
{
    Varyings Output;
    
    UNITY_SETUP_INSTANCE_ID(Input);
    UNITY_TRANSFER_INSTANCE_ID(Input, Output);
    
    float3 positionWS = TransformObjectToWorld(Input.positionOS);    
    Output.positionOS = TransformWorldToHClip(positionWS);
    
    return Output;    
}

float4 UnlitPassFragment(Varyings Input) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(Input);
    return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Color);
}

#endif