#ifndef _CRP_LIT_INPUT_INCLUDED_
#define _CRP_LIT_INPUT_INCLUDED_

TEXTURE2D(_ColorTexture);
SAMPLER(sampler_ColorTexture);

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
    UNITY_DEFINE_INSTANCED_PROP(float4, _ColorTexture_ST)
    UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
    UNITY_DEFINE_INSTANCED_PROP(float,  _Metallic)
    UNITY_DEFINE_INSTANCED_PROP(float,  _Smoothness)
    UNITY_DEFINE_INSTANCED_PROP(float,  _Cutoff)
UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
//--------------------------------------------------------------------------------------

float4 GetColorTexture_ST()
{
    return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _ColorTexture_ST);
}

float4 GetColor()
{
    return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Color);
}

float GetMetallic()
{
    return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Metallic);
}

float GetSmoothness()
{
    return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Smoothness);
}

float GetCutoff()
{
    return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff);
}

#endif