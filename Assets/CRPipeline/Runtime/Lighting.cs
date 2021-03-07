using UnityEngine;
using UnityEngine.Rendering;

namespace CRP
{
    public class Lighting
    {
        private const string BufferName = "Lighting";
        private CommandBuffer _cmdBuffer = new CommandBuffer {name = BufferName};
        
        private const int MaxDirLightCount = 4;
        private static Vector4[] _dirLightColors     = new Vector4[MaxDirLightCount];
        private static Vector4[] _dirLightDirections = new Vector4[MaxDirLightCount];
        private static Vector4[] _dirLightShadowData = new Vector4[MaxDirLightCount]; // shadow strength; shadow atlas tile index for Cascade[0]; normal bias
        
        private Shadows _shadows = new Shadows();
        

        public void Setup(ScriptableRenderContext context, CullingResults cullingResults, ShadowSettings shadowSettings)
        {
            _cmdBuffer.BeginSample(BufferName);
            {
                _shadows.Init(context, cullingResults, shadowSettings);
                SetupLights(_cmdBuffer, cullingResults);
                _shadows.Render();
            }
            _cmdBuffer.EndSample(BufferName);
            
            context.ExecuteCommandBuffer(_cmdBuffer);
            _cmdBuffer.Clear();
        }

        public void Cleanup()
        {
            _shadows.Cleanup();
        }

        private void SetupLights(CommandBuffer cmdBuffer, in CullingResults cullingResults)
        {
            var visibleLights = cullingResults.visibleLights;

            int directionalLightsCount = 0;
            
            for (int i = 0; i < visibleLights.Length; ++i)
            {
                var visibleLight = visibleLights[i];

                if (visibleLight.lightType == LightType.Directional && directionalLightsCount < MaxDirLightCount)
                {
                    SetupDirectionalLight(directionalLightsCount++, visibleLight);
                }
            }
            
            cmdBuffer.SetGlobalInt(CRPShaderIDs._DirectionalLightCount, directionalLightsCount);
            cmdBuffer.SetGlobalVectorArray(CRPShaderIDs._DirectionalLightColors,     _dirLightColors);
            cmdBuffer.SetGlobalVectorArray(CRPShaderIDs._DirectionalLightDirections, _dirLightDirections);
            cmdBuffer.SetGlobalVectorArray(CRPShaderIDs._DirectionalLightShadowData, _dirLightShadowData);
        }

        private void SetupDirectionalLight(int index, in VisibleLight visibleLight)
        {
            _dirLightColors    [index] =  visibleLight.finalColor; // linear space due to GraphicsSettings.lightsUseLinearIntensity == true
            _dirLightDirections[index] = -visibleLight.localToWorldMatrix.GetColumn(2);
            _dirLightShadowData[index] = _shadows.ReserveDirectionalLightShadow(visibleLight.light, index);
        }
    }
}