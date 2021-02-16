Shader "CRP/Lit"
{
    Properties
    {
        _ColorTexture("Color texture", 2D) = "white" {}
        _Color("Color", Color) = (0.5, 0.5, 0.5, 1.0)
        
        [Toggle(USE_ALPHA_CLIPPING)] _AlphaTesting("Alpha clipping", Float) = 0
        _Cutoff("Cutoff", Range(0.0, 1.0)) = 0.5
        
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 1.0        
        [Enum(Off, 0, On, 1)]                   _ZWrite   ("Z Write"  , Float) = 1.0
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
            //#pragma instancing_options assumeuniformscaling
            
            #pragma vertex   LitPassVertex
            #pragma fragment LitPassFragment
                        
            #include "LitPass.hlsl"
            ENDHLSL        
        }
    }
}