Shader "CRP/Unlit"
{
    Properties
    {
        _ColorTexture("Color texture", 2D) = "white" {}
        _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        
        [Toggle(USE_ALPHA_CLIPPING)] _AlphaClipping("Alpha clipping", Float) = 0
        _Cutoff("Cutoff", Range(0.0, 1.0)) = 0.5
        
        [KeywordEnum(Clip, Dither)] _Shadows("Shadows", Float) = 0
        
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
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
                
            HLSLPROGRAM
            #pragma multi_compile_instancing
            #pragma shader_feature USE_ALPHA_CLIPPING
            #pragma shader_feature _ _DIRECTIONAL_PCF3 _DIRECTIONAL_PCF5 _DIRECTIONAL_PCF7
            #pragma shader_feature _ _CASCADE_BLEND_SOFT _CASCADE_BLEND_DITHER
            
            #pragma vertex   UnlitPassVertex
            #pragma fragment UnlitPassFragment
                        
            #include "UnlitPass.hlsl"
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
            
            #include "UnlitShadowCasterPass.hlsl"
            ENDHLSL
        }
    }
    
    CustomEditor "CRP.Editor.LitUnlitShaderGUI"
}