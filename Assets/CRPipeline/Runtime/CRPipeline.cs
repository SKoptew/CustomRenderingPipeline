using UnityEngine;
using UnityEngine.Rendering;

namespace CRP
{
    public class CRPipeline : RenderPipeline
    {
        private bool _useDynamicBatching;
        private bool _useGPUInstancing;
        
        private CameraRenderer _camRenderer = new CameraRenderer();

        public CRPipeline(bool useDynamicBatching, bool useGPUInstancing, bool useSRPBatcher)
        {
            _useDynamicBatching = useDynamicBatching;
            _useGPUInstancing   = useGPUInstancing;
            
            GraphicsSettings.useScriptableRenderPipelineBatching = useSRPBatcher;
            GraphicsSettings.lightsUseLinearIntensity = true;
        }
        
        protected override void Render(ScriptableRenderContext context, Camera[] cameras)
        {
            foreach (var camera in cameras)
            {
                _camRenderer.Render(context, camera, _useDynamicBatching, _useGPUInstancing);
            }
        }
    }
}
