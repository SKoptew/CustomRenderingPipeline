Shader "CRP/Unlit"
{
    Properties
    {
        _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
    }
    
    SubShader
    {
        Pass
        {
            HLSLPROGRAM
            #pragma multi_compile_instancing            
            #pragma vertex   UnlitPassVertex
            #pragma fragment UnlitPassFragment
                        
            #include "Unlit.hlsl"
            ENDHLSL        
        }
    }
}