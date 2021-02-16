using UnityEngine;
using UnityEngine.Rendering;

namespace CRP
{
    public class Lighting
    {
        private const string BufferName = "LightingCmdBuffer";
        private CommandBuffer _cmdBuffer = new CommandBuffer {name = BufferName};
        
        private const int MaxDirLightCount = 4;
        private static Vector4[] _dirLightColors     = new Vector4[MaxDirLightCount];
        private static Vector4[] _dirLightDirections = new Vector4[MaxDirLightCount];

        public void Setup(ScriptableRenderContext context, CullingResults cullingResults)
        {
            _cmdBuffer.BeginSample(BufferName);
            SetupLights(_cmdBuffer, cullingResults);
            _cmdBuffer.EndSample(BufferName);
            
            context.ExecuteCommandBuffer(_cmdBuffer);
            _cmdBuffer.Clear();
        }

        private static void SetupLights(CommandBuffer cmdBuffer, in CullingResults cullingResults)
        {
            var visibleLights = cullingResults.visibleLights;

            int directionalLightsCount = 0;
            
            for (int i = 0; i < visibleLights.Length; ++i)
            {
                var light = visibleLights[i];

                if (light.lightType == LightType.Directional && directionalLightsCount < MaxDirLightCount)
                {
                    SetupDirectionalLight(directionalLightsCount++, light);
                }
            }
            
            cmdBuffer.SetGlobalInt(CRPShaderIDs._DirectionalLightCount, directionalLightsCount);
            cmdBuffer.SetGlobalVectorArray(CRPShaderIDs._DirectionalLightColors, _dirLightColors);
            cmdBuffer.SetGlobalVectorArray(CRPShaderIDs._DirectionalLightDirections, _dirLightDirections);
        }

        private static void SetupDirectionalLight(int index, in VisibleLight light)
        {
            _dirLightColors    [index] = light.finalColor; // linear space due to GraphicsSettings.lightsUseLinearIntensity == true
            _dirLightDirections[index] = -light.localToWorldMatrix.GetColumn(2);
        }
    }
}