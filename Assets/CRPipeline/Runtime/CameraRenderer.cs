using UnityEngine;
using UnityEngine.Rendering;

namespace CRP
{
    public partial class CameraRenderer
    {
        private ScriptableRenderContext _context;
        private Camera                  _camera;
        private CommandBuffer           _cmd = new CommandBuffer();
        private CullingResults          _cullingResults;
        
        private Lighting _lighting = new Lighting();

        private static class ProfilingSampleNames
        {
            public const string ClearRT = "Clear RT";
        }

        private static partial class CRPShaderTags
        {
            public static readonly ShaderTagId Unlit  = new ShaderTagId("SRPDefaultUnlit");
            public static readonly ShaderTagId CRPLit = new ShaderTagId("CRPLit");            // Tags { "LightMode" = "CRPLit" }
        }

        public void Render(ScriptableRenderContext context, Camera camera, bool useDynamicBatching, bool useGPUInstancing)
        {
            _context = context;
            _camera = camera;

            PrepareCommandBuffer();
            PrepareForSceneWindow();

            if (!Cull())
                return;

            SetupCameraProperties();
            _lighting.Setup(context, _cullingResults);
            DrawVisibleGeometry(useDynamicBatching, useGPUInstancing);
            DrawUnsupportedShaders();
            DrawGizmos();

            Submit();
        }

        private void ExecuteBuffer()
        {
            _context.ExecuteCommandBuffer(_cmd);
            _cmd.Clear();
        }

        private void SetupCameraProperties()
        {
            _context.SetupCameraProperties(_camera); // before ClearRenderTarget to more effective way
            
            _cmd.BeginSample(ProfilingSampleNames.ClearRT);
            {
                var flags = _camera.clearFlags;
                
                _cmd.ClearRenderTarget(
                    flags != CameraClearFlags.Nothing, 
                    flags == CameraClearFlags.Color, 
                    flags == CameraClearFlags.Color ? _camera.backgroundColor.linear : Color.clear);
            }
            _cmd.EndSample(ProfilingSampleNames.ClearRT);
            
            _cmd.BeginSample(ProfilingSampleName);
            ExecuteBuffer();
        }

        private void DrawVisibleGeometry(bool useDynamicBatching, bool useGPUInstancing)
        {
            var sortingSettings = new SortingSettings(_camera);

            var drawingSettings = new DrawingSettings(CRPShaderTags.Unlit, sortingSettings)
            {
                enableDynamicBatching = useDynamicBatching,
                enableInstancing      = useGPUInstancing
            };
            drawingSettings.SetShaderPassName(1, CRPShaderTags.CRPLit);

            //-- draw opaque unlit objects
            {
                sortingSettings.criteria = SortingCriteria.CommonOpaque;
                var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);

                _context.DrawRenderers(_cullingResults, ref drawingSettings, ref filteringSettings);
            }

            _context.DrawSkybox(_camera);

            //-- draw transparent unlit objects
            {
                sortingSettings.criteria = SortingCriteria.CommonTransparent;
                var filteringSettings = new FilteringSettings(RenderQueueRange.transparent);
                
                _context.DrawRenderers(_cullingResults, ref drawingSettings, ref filteringSettings);
            }
        }

        private void Submit()
        {
            _cmd.EndSample(ProfilingSampleName);
            ExecuteBuffer();
            
            _context.Submit();
        }

        private bool Cull()
        {
            if (_camera.TryGetCullingParameters(out var cullingParameters))
            {
                _cullingResults = _context.Cull(ref cullingParameters);
                return true;
            }

            return false;
        }

        partial void PrepareCommandBuffer();
        partial void PrepareForSceneWindow();
        partial void DrawUnsupportedShaders();
        partial void DrawGizmos();
    }
}