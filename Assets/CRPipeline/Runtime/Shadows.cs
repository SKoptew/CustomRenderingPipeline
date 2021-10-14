using UnityEngine;
using UnityEngine.Rendering;

namespace CRP
{
    public class Shadows
    {
        private static class ProfilingSampleNames
        {
            public const string DirectionalShadows = "Directional shadows";
        }

        private static string[] DirectionalFilterKeywords =
        {
            "_DIRECTIONAL_PCF3",
            "_DIRECTIONAL_PCF5",
            "_DIRECTIONAL_PCF7"
        };

        private ScriptableRenderContext _renderContext;
        private CullingResults          _cullingResults;
        private ShadowSettings          _shadowSettings;
        
        private const string BufferName = "Shadows";
        private CommandBuffer _cmdBuffer = new CommandBuffer {name = BufferName};

        struct DirectionalShadow
        {
            public int   visibleLightIndex; // idx of corresponding light in cullingResults.visibleLights[]
            public float slopeScaleBias;
            public float nearPlaneOffset;
        }
        
        private const int MaxDirectionalShadowCount = 4;
        private const int MaxCascades = 4;
        
        private int _directionalShadowCount   = 0;
        private DirectionalShadow[] _directionalShadows        = new DirectionalShadow[MaxDirectionalShadowCount];
        private Matrix4x4[]         _directionalShadowMatrices = new Matrix4x4        [MaxDirectionalShadowCount*MaxCascades]; // view*proj*toUV. positionWS => texAtlasUV
        private Vector4[]           _cascadeCullingSpheres     = new Vector4          [MaxCascades]; // float3: center, float: rad^2
        private Vector4[]           _cascadeData               = new Vector4          [MaxCascades]; // 1/cullingSphere.w^2


        public void Init(ScriptableRenderContext renderContext, CullingResults cullingResults, ShadowSettings shadowSettings)
        {
            _renderContext  = renderContext;
            _cullingResults = cullingResults;
            _shadowSettings = shadowSettings;
            _directionalShadowCount = 0;
        }

        public Vector3 ReserveDirectionalLightShadow(Light light, int visibleLightIndex)
        {
            if (  _directionalShadowCount < MaxDirectionalShadowCount
               && light.shadows != LightShadows.None && light.shadowStrength > 0f                          // light have shadows enabled
               && _cullingResults.GetShadowCasterBounds(visibleLightIndex, out Bounds shadowCasterBounds)) // light affects any objects that cast shadows
            {
                _directionalShadows[_directionalShadowCount] = new DirectionalShadow
                {
                    visibleLightIndex = visibleLightIndex,
                    slopeScaleBias    = light.shadowBias,
                    nearPlaneOffset   = light.shadowNearPlane
                };
                
                return new Vector3(
                    light.shadowStrength, 
                    (_directionalShadowCount++) * _shadowSettings.directional.cascadeCount,
                    light.shadowNormalBias
                    );
            }
            return Vector3.zero;
        }

        public void Render()
        {
            RenderDirectionalShadows(_renderContext, _cmdBuffer);
        }

        public void Cleanup()
        {
            if (_directionalShadowCount > 0)
            {
                _cmdBuffer.ReleaseTemporaryRT(CRPShaderIDs._DirectionalShadowAtlas);
                ExecuteAndClearCmdBuffer(_renderContext, _cmdBuffer);
            }
        }

        private void RenderDirectionalShadows(ScriptableRenderContext renderContext, CommandBuffer cmd)
        {
            if (_directionalShadowCount <= 0)
                return;
            
            cmd.BeginSample(ProfilingSampleNames.DirectionalShadows);
            {
                //-- allocate or get (if already exists) square RenderTexture for dir shadow atlas
                int atlasSize = (int) _shadowSettings.directional.atlasSize;
                cmd.GetTemporaryRT(
                    CRPShaderIDs._DirectionalShadowAtlas, 
                    atlasSize, atlasSize, 
                    32, 
                    FilterMode.Bilinear, 
                    RenderTextureFormat.Shadowmap);
                
                cmd.SetRenderTarget(CRPShaderIDs._DirectionalShadowAtlas, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
                cmd.ClearRenderTarget(true, false, Color.clear);

                
                int tiles = _directionalShadowCount * _shadowSettings.directional.cascadeCount;
                int split = CalcSplitCount(_directionalShadowCount, tiles);
                int tileSize = atlasSize / split;

                //-- render shadow texture atlas; store tiles matrices
                for (int i = 0; i < _directionalShadowCount; ++i)
                {
                    RenderDirectionalShadow(renderContext, cmd, i, split, tileSize);
                }
                
                cmd.SetGlobalVector     (CRPShaderIDs._ShadowAtlasSize, new Vector4(atlasSize, 1f/atlasSize));
                cmd.SetGlobalVector     (CRPShaderIDs._ShadowDistanceFade,  CalcShadowDistanceFadeParameters(_shadowSettings));
                cmd.SetGlobalMatrixArray(CRPShaderIDs._DirectionalShadowMatrices, _directionalShadowMatrices);
                cmd.SetGlobalInt        (CRPShaderIDs._CascadeCount,        _shadowSettings.directional.cascadeCount);
                cmd.SetGlobalVectorArray(CRPShaderIDs._CascadeCullingSpheres,     _cascadeCullingSpheres);
                cmd.SetGlobalVectorArray(CRPShaderIDs._CascadeData,               _cascadeData);
                
                SetKeywords(_shadowSettings.directional.filterMode, cmd);
            }
            cmd.EndSample(ProfilingSampleNames.DirectionalShadows);
            
            ExecuteAndClearCmdBuffer(renderContext, cmd);
        }

        private void RenderDirectionalShadow(ScriptableRenderContext renderContext, CommandBuffer cmd, int index, int split, int tileSize)
        {
            var shadow = _directionalShadows[index];
            var shadowSettings = new ShadowDrawingSettings(_cullingResults, shadow.visibleLightIndex);
            
            int cascadeCount = _shadowSettings.directional.cascadeCount;
            int tileOffset = index * cascadeCount;
            Vector3 ratios = _shadowSettings.directional.CascadeRatios;

            for (int cascadeIdx = 0; cascadeIdx < cascadeCount; ++cascadeIdx)
            {
                _cullingResults.ComputeDirectionalShadowMatricesAndCullingPrimitives(
                    shadow.visibleLightIndex,
                    cascadeIdx, cascadeCount, ratios,
                    tileSize,
                    shadow.nearPlaneOffset,
                    out var viewMatrix,
                    out var projMatrix,
                    out var shadowSplitData);
                
                shadowSettings.splitData = shadowSplitData;

                //-- spheres for all dir light are the same => store values for first dir light
                if (index == 0)
                    SetCascadeData(cascadeIdx, shadowSplitData.cullingSphere, tileSize);

                int tileIndex = tileOffset + cascadeIdx;
                _directionalShadowMatrices[tileIndex] = ConvertToAtlasMatrix(projMatrix * viewMatrix, SetTileViewport(cmd, tileIndex, split, tileSize), split);
                
                cmd.SetViewProjectionMatrices(viewMatrix, projMatrix);
                cmd.SetGlobalDepthBias(0f, shadow.slopeScaleBias);
                ExecuteAndClearCmdBuffer(renderContext, cmd);
                
                renderContext.DrawShadows(ref shadowSettings); //-- render objects with materials that have "ShadowCaster" pass
                cmd.SetGlobalDepthBias(0f, 0f);
            }
        }

        private void SetCascadeData(int cascadeIdx, Vector4 cullingSphere, float tileSize)
        {
            float texelSize  = 2f * cullingSphere.w / tileSize;
            float filterSize = texelSize * ((int) _shadowSettings.directional.filterMode + 1);

            cullingSphere.w -= filterSize; // prevent sampling outside of the cascade's culling sphere
            cullingSphere.w *= cullingSphere.w;
            
            _cascadeData[cascadeIdx] = new Vector4(
                1f / cullingSphere.w, 
                filterSize * Mathf.Sqrt(2f),
                0, 
                0);

            _cascadeCullingSpheres[cascadeIdx] = cullingSphere;
        }

        private static int CalcSplitCount(int directionalShadowCount, int tiles)
        {
            // up to 4x4 atlas, 1..4 dir lights with shadows; 1..4 shadow cascades for each light
            int split = tiles <= 1 ? 1 
                                   : tiles <= 4 ? 2 : 4;

            return split;
        }

        private static Vector4 CalcShadowDistanceFadeParameters(ShadowSettings settings)
        {
            float f = 1f - settings.directional.cascadeFade;
            
            return new Vector4(1f / settings.maxDistance, 1f / settings.distanceFade, 1f/(1f - f*f));
        }

        private static Vector2 SetTileViewport(CommandBuffer cmdBuffer, int index, int split, float tileSize)
        {
            var offset = new Vector2(index % split, index / split);
            cmdBuffer.SetViewport(new Rect(offset.x * tileSize, offset.y * tileSize, tileSize, tileSize));

            return offset;
        }

        static void SetKeywords(ShadowSettings.ShadowFilterMode mode, CommandBuffer cmd)
        {
            int enabledIndex = (int)mode - 1;

            for (int i = 0; i < DirectionalFilterKeywords.Length; ++i)
            {
                if (i == enabledIndex)
                    cmd.EnableShaderKeyword(DirectionalFilterKeywords[i]);
                else
                    cmd.DisableShaderKeyword(DirectionalFilterKeywords[i]);
            }
        }
        
        static Matrix4x4 ConvertToAtlasMatrix(Matrix4x4 m, Vector2 offset, int split) 
        {
            // clip space: [-1..1] => UV space: [0..0]
            // scale and offset according to tile number
            
            if (SystemInfo.usesReversedZBuffer) 
            {
                m.m20 = -m.m20;
                m.m21 = -m.m21;
                m.m22 = -m.m22;
                m.m23 = -m.m23;
            }
            
            float scale = 1f / split;
            m.m00 = (0.5f * (m.m00 + m.m30) + offset.x * m.m30) * scale;
            m.m01 = (0.5f * (m.m01 + m.m31) + offset.x * m.m31) * scale;
            m.m02 = (0.5f * (m.m02 + m.m32) + offset.x * m.m32) * scale;
            m.m03 = (0.5f * (m.m03 + m.m33) + offset.x * m.m33) * scale;
            
            m.m10 = (0.5f * (m.m10 + m.m30) + offset.y * m.m30) * scale;
            m.m11 = (0.5f * (m.m11 + m.m31) + offset.y * m.m31) * scale;
            m.m12 = (0.5f * (m.m12 + m.m32) + offset.y * m.m32) * scale;
            m.m13 = (0.5f * (m.m13 + m.m33) + offset.y * m.m33) * scale;
            
            m.m20 = 0.5f * (m.m20 + m.m30);
            m.m21 = 0.5f * (m.m21 + m.m31);
            m.m22 = 0.5f * (m.m22 + m.m32);
            m.m23 = 0.5f * (m.m23 + m.m33);
            
            return m;
        }

        private static void ExecuteAndClearCmdBuffer(ScriptableRenderContext renderContext, CommandBuffer cmd)
        {
            renderContext.ExecuteCommandBuffer(cmd);
            cmd.Clear();
        }
    }
}