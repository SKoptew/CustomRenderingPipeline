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
            public const string ClearRT       = "Clear RT";
            public const string LightingSetup = "Lighting setup";
        }

        public void Render(ScriptableRenderContext context, Camera camera, bool useDynamicBatching, bool useGPUInstancing, ShadowSettings shadowSettings)
        {
            _context = context;
            _camera = camera;

            PrepareCommandBuffer();
            PrepareForSceneWindow();

            if (!Cull(shadowSettings.maxDistance))
                return;
            
            _cmd.BeginSample(ProfilingSampleNames.LightingSetup); // place shadows frame debugger entry inside the camera's
            ExecuteBuffer();
            _lighting.Setup(context, _cullingResults, shadowSettings);
            _cmd.EndSample(ProfilingSampleNames.LightingSetup);

            SetupCameraProperties();
            DrawVisibleGeometry(useDynamicBatching, useGPUInstancing);
            DrawUnsupportedShaders();
            DrawGizmos();

            _lighting.Cleanup();
            
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

            var drawingSettings = new DrawingSettings(CRPShaderPassTags.Unlit, sortingSettings)
            {
                enableDynamicBatching = useDynamicBatching,
                enableInstancing      = useGPUInstancing,
                perObjectData         = PerObjectData.Lightmaps // send lightmapUV data to obj  
            };
            drawingSettings.SetShaderPassName(1, CRPShaderPassTags.CRPLit);

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

        private bool Cull(float maxShadowDistance)
        {
            if (_camera.TryGetCullingParameters(out var cullingParameters))
            {
                cullingParameters.shadowDistance = Mathf.Min(maxShadowDistance, _camera.farClipPlane);
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