using UnityEngine;
using UnityEngine.Rendering;

namespace CRP
{
    public class CRPipeline : RenderPipeline
    {
        private bool           _useDynamicBatching;
        private bool           _useGPUInstancing;
        private ShadowSettings _shadowSettings;
        
        private CameraRenderer _camRenderer = new CameraRenderer();

        public CRPipeline(bool useDynamicBatching, bool useGPUInstancing, bool useSRPBatcher, ShadowSettings shadowSettings)
        {
            _useDynamicBatching = useDynamicBatching;
            _useGPUInstancing   = useGPUInstancing;
            _shadowSettings     = shadowSettings;
            
            GraphicsSettings.useScriptableRenderPipelineBatching = useSRPBatcher;
            GraphicsSettings.lightsUseLinearIntensity = true;
        }
        
        protected override void Render(ScriptableRenderContext context, Camera[] cameras)
        {
            foreach (var camera in cameras)
            {
                _camRenderer.Render(context, camera, _useDynamicBatching, _useGPUInstancing, _shadowSettings);
            }
        }
    }
}
