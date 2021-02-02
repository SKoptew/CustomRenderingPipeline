using UnityEngine;
using UnityEngine.Rendering;

namespace CRP
{
    public class CRPipeline : RenderPipeline
    {
        private CameraRenderer _camRenderer = new CameraRenderer();
        
        protected override void Render(ScriptableRenderContext context, Camera[] cameras)
        {
            foreach (var camera in cameras)
            {
                _camRenderer.Render(context, camera);
            }
        }
    }
}
