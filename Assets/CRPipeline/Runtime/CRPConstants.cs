using UnityEngine;
using UnityEngine.Rendering;

namespace CRP
{
    public static class CRPShaderPassTags
    {
        public static readonly ShaderTagId Unlit  = new ShaderTagId("SRPDefaultUnlit");
        public static readonly ShaderTagId CRPLit = new ShaderTagId("CRPLit");            // Tags { "LightMode" = "CRPLit" }
        
        public static readonly ShaderTagId[] Legacy =
        {
            new ShaderTagId("Always"),
            new ShaderTagId("ForwardBase"),
            new ShaderTagId("Deferred"),
            new ShaderTagId("PrepassBase"),
            new ShaderTagId("Vertex"),
            new ShaderTagId("VertexLMRGBM"),
            new ShaderTagId("VertexLM"), 
        };
    }

    public static class CRPShaderIDs
    {
        // Global variables
        public static readonly int _DirectionalLightCount      = Shader.PropertyToID("_DirectionalLightCount");
        public static readonly int _DirectionalLightColors     = Shader.PropertyToID("_DirectionalLightColors");
        public static readonly int _DirectionalLightDirections = Shader.PropertyToID("_DirectionalLightDirections");
    }
}