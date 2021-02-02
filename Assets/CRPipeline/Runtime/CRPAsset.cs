using UnityEngine;
using UnityEngine.Rendering;

namespace CRP
{
    [CreateAssetMenu(menuName = "Rendering/Custom Render Pipeline")]
    public class CRPAsset : RenderPipelineAsset
    {
        protected override RenderPipeline CreatePipeline()
        {
            return new CRPipeline();
        }
    }
}