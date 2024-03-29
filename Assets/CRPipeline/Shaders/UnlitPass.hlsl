#ifndef _CRP_UNLIT_PASS_INCLUDED_
#define _CRP_UNLIT_PASS_INCLUDED_

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
    float2 UV         : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

#include "UnlitInput.hlsl"
//---------------------------------------------------------------------------------------

//-- vertex shader returns positionCS: homogeneous clip space, (x y z w). then, /= w => NDC
Varyings UnlitPassVertex(Attributes Input)
{
    Varyings Output;
    
    UNITY_SETUP_INSTANCE_ID(Input);             // UnitySetupInstanceID(IN.instanceID); // unity_InstanceID = inputInstanceID + unity_BaseInstanceID;
    UNITY_TRANSFER_INSTANCE_ID(Input, Output);
    
    float3 positionWS = TransformObjectToWorld(Input.positionOS);    
    Output.positionCS = TransformWorldToHClip(positionWS);
    
    const float4 uv_ST = GetColorTexture_ST();
    Output.UV = Input.UV * uv_ST.xy + uv_ST.zw;
    
    return Output;    
}

float4 UnlitPassFragment(Varyings Input) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(Input);
    
    float4 color = SAMPLE_TEXTURE2D(_ColorTexture, sampler_ColorTexture, Input.UV) * GetColor();
    
#ifdef USE_ALPHA_CLIPPING
    clip(color.a - UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, GetCutoff()));
#endif
    
    return color;
}

#endif