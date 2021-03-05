using UnityEngine;
using UnityEngine.Rendering;

namespace CRP
{
    [CreateAssetMenu(menuName = "Rendering/Custom Render Pipeline")]
    public class CRPAsset : RenderPipelineAsset
    {
        [SerializeField]
        private bool _useDynamicBathing = true,
                     _useGPUInstancing  = true,
                     _useSRPBatcher     = true;

        [SerializeField] 
        private ShadowSettings _shadowSettings;
        
        protected override RenderPipeline CreatePipeline()
        {
            return new CRPipeline(_useDynamicBathing, _useGPUInstancing, _useSRPBatcher, _shadowSettings);
        }
    }
}