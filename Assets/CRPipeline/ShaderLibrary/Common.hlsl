#ifndef _CRP_COMMON_INCLUDED_
#define _CRP_COMMON_INCLUDED_

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"           //-- API header (like API/D3D11.hlsl), Macros.hlsl, Random.hlsl
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"   //-- helpers for BRDF parameters

#include "Assets/CRPipeline/ShaderLibrary/ShaderVariables.hlsl"

#define UNITY_MATRIX_M   unity_ObjectToWorld
#define UNITY_MATRIX_I_M unity_WorldToObject
#define UNITY_MATRIX_V   unity_MatrixV
#define UNITY_MATRIX_VP  unity_MatrixVP
#define UNITY_MATRIX_P   glstate_matrix_projection

//-- if Instancing enabled - redefines matrices defines above
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

float Square(float x)
{
    return x*x;
}

float DistanceSquared(float3 p0, float3 p1)
{
    float3 d = p1-p0;
    return dot(d, d);
}

#endif