Shader "CRP/Lit"
{
    Properties
    {
        _ColorTexture("Color texture", 2D)         = "white" {}
        _Color       ("Color",         Color)      = (0.5, 0.5, 0.5, 1.0)
        _Metallic    ("Metallic",      Range(0,1)) = 0.0
        _Smoothness  ("Smoothness",    Range(0,1)) = 0.5
        
        [Toggle(USE_ALPHA_CLIPPING)] _AlphaClipping("Alpha clipping", Float) = 0
        _Cutoff("Cutoff", Range(0.0, 1.0)) = 0.5
        
        [Toggle(PREMULTIPLY_ALPHA)] _PreMulAlpha("Premultiply alpha", Float) = 0
        
        [KeywordEnum(Clip, Dither)] _Shadows("Shadows", Float) = 0
        [Toggle(_RECEIVE_SHADOWS)] _ReceiveShadows("Receive shadows", Float) = 1
        
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src blend", Float) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst blend", Float) = 1.0        
        [Enum(Off, 0, On, 1)]                   _ZWrite   ("Z write"  , Float) = 1.0
    }
    
    SubShader
    {
        Tags 
        {
            "RenderType" = "Opaque"   // needed for replacement shaders
            "Queue"      = "Geometry" // Geometry [+ 1] / AlphaTest / Transparent
        }
        
        Pass
        {
            Tags { "LightMode" = "CRPLit" }
        
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
                
            HLSLPROGRAM
            #pragma target 3.5            
            #pragma multi_compile_instancing
            #pragma shader_feature USE_ALPHA_CLIPPING
            #pragma shader_feature PREMULTIPLY_ALPHA
            #pragma shader_feature _ _DIRECTIONAL_PCF3 _DIRECTIONAL_PCF5 _DIRECTIONAL_PCF7
            #pragma shader_feature _ _CASCADE_BLEND_SOFT _CASCADE_BLEND_DITHER
            #pragma shader_feature _RECEIVE_SHADOWS
            #pragma multi_compile _ LIGHTMAP_ON
            //#pragma instancing_options assumeuniformscaling
            
            #pragma vertex   LitPassVertex
            #pragma fragment LitPassFragment
                        
            #include "LitPass.hlsl"
            ENDHLSL        
        }
        
        Pass
        {
            Tags { "LightMode" = "ShadowCaster" }
            
            ColorMask 0
            
            HLSLPROGRAM
            #pragma target 3.5
            #pragma multi_compile_instancing
            #pragma shader_feature _ _SHADOWS_CLIP _SHADOWS_DITHER
            
            #pragma vertex   ShadowCasterPassVertex
            #pragma fragment ShadowCasterPassFragment
            
            #include "LitShadowCasterPass.hlsl"
            ENDHLSL
        }
        
        Pass
        {
            Tags { "LightMode" = "Meta" } // for lightmap baking
            
            Cull Off
            
            HLSLPROGRAM
            #pragma target 3.5
            
            #pragma vertex   LitMetaPassVertex
            #pragma fragment LitMetaPassFragment
            
            #include "LitMetaPass.hlsl"
            ENDHLSL
        }
    }
    
    CustomEditor "CRP.Editor.LitUnlitShaderGUI"
}