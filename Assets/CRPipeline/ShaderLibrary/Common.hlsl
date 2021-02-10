#ifndef _CRP_COMMON_INCLUDED_
#define _CRP_COMMON_INCLUDED_

#include "Assets/CRPipeline/ShaderLibrary/ShaderVariables.hlsl"

#define UNITY_MATRIX_M   unity_ObjectToWorld
#define UNITY_MATRIX_I_M unity_WorldToObject
#define UNITY_MATRIX_V   unity_MatrixV
#define UNITY_MATRIX_VP  unity_MatrixVP
#define UNITY_MATRIX_P   glstate_matrix_projection

//-- if Instancing enabled - redefines matrices defines above
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"



#endif