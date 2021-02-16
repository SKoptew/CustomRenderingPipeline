using UnityEditor;
using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.Rendering;

namespace CRP
{
    partial class CameraRenderer
    {
#if UNITY_EDITOR
        private static Material _errorMaterial;
        
        private string ProfilingSampleName { get; set; }

        partial class CRPShaderTags
        {
            public static readonly ShaderTagId[] Legacy =
            {
                new ShaderTagId("Always"),
                new ShaderTagId("ForwardBase"),
                new ShaderTagId("PrepassBase"),
                new ShaderTagId("Vertex"),
                new ShaderTagId("VertexLMRGBM"),
                new ShaderTagId("VertexLM"), 
            };
        }

        partial void PrepareCommandBuffer()
        {
            Profiler.BeginSample("PrepareCommandBuffer");
            _cmd.name = ProfilingSampleName = _camera.name;        // access to _camera.name allocates 100 bytes; cache it
            Profiler.EndSample();
        }
        
        partial void PrepareForSceneWindow()
        {
            if (_camera.cameraType == CameraType.SceneView)
                ScriptableRenderContext.EmitWorldGeometryForSceneView(_camera);
        }
        
        partial void DrawUnsupportedShaders()
        {
            if (_errorMaterial == null)
                _errorMaterial = new Material(Shader.Find("Hidden/InternalErrorShader"));
            
            var drawingSettings = new DrawingSettings(CRPShaderTags.Legacy[0], new SortingSettings(_camera))
            {
                overrideMaterial = _errorMaterial
            };
            
            for (int i = 1; i < CRPShaderTags.Legacy.Length; ++i)
                drawingSettings.SetShaderPassName(i, CRPShaderTags.Legacy[i]);
            
            var filteringSettings = FilteringSettings.defaultValue;
            
            _context.DrawRenderers(_cullingResults, ref drawingSettings, ref filteringSettings);
        }

        partial void DrawGizmos()
        {
            if (Handles.ShouldRenderGizmos())
            {
                _context.DrawGizmos(_camera, GizmoSubset.PreImageEffects);
                _context.DrawGizmos(_camera, GizmoSubset.PostImageEffects);
            }
        }
#else
    const string ProfilingSampleName = "Camera command buffer";
#endif
    }
}
