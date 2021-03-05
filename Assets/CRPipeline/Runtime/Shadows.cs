using UnityEngine;
using UnityEngine.Rendering;

namespace CRP
{
    public class Shadows
    {
        private const string BufferName = "Shadows";
        private CommandBuffer _cmdBuffer = new CommandBuffer {name = BufferName};
        
        private static class ProfilingSampleNames
        {
            public const string DirectionalShadows = "Directional shadows";
        }

        private ScriptableRenderContext _context;
        private CullingResults          _cullingResults;
        private ShadowSettings          _shadowSettings;

        struct DirectionalShadow
        {
            public int visibleLightIndex; // idx of corresponding light in cullingResults.visibleLights[]
        }
        
        private const int MaxDirectionalShadowCount = 4;
        private       int _directionalShadowCount   = 0;
        private DirectionalShadow[] _directionalShadows       = new DirectionalShadow[MaxDirectionalShadowCount];
        private Matrix4x4[]        _directionalShadowMatrices = new Matrix4x4        [MaxDirectionalShadowCount]; // view*proj*toUV. positionWS => texAtlasUV


        public void Init(ScriptableRenderContext context, CullingResults cullingResults, ShadowSettings shadowSettings)
        {
            _context        = context;
            _cullingResults = cullingResults;
            _shadowSettings = shadowSettings;
            _directionalShadowCount = 0;
        }

        public Vector2 ReserveDirectionalLightShadow(Light light, int visibleLightIndex)
        {
            if (  _directionalShadowCount < MaxDirectionalShadowCount
               && light.shadows != LightShadows.None && light.shadowStrength > 0f                          // light have shadows enabled
               && _cullingResults.GetShadowCasterBounds(visibleLightIndex, out Bounds shadowCasterBounds)) // light affects any objects that cast shadows
            {
                _directionalShadows[_directionalShadowCount] = new DirectionalShadow {visibleLightIndex = visibleLightIndex};
                
                return new Vector2(light.shadowStrength, _directionalShadowCount++);
            }
            return Vector2.zero;
        }

        public void Render()
        {
            RenderDirectionalShadows();
        }

        public void Cleanup()
        {
            if (_directionalShadowCount > 0)
            {
                _cmdBuffer.ReleaseTemporaryRT(CRPShaderIDs._DirectionalShadowAtlas);
                ExecuteAndClearCmdBuffer();
            }
        }

        private void RenderDirectionalShadows()
        {
            if (_directionalShadowCount <= 0)
                return;
            
            _cmdBuffer.BeginSample(ProfilingSampleNames.DirectionalShadows);
            {
                //-- allocate or get (if already exists) square RenderTexture for dir shadow atlas
                int atlasSize = (int) _shadowSettings.directional.atlasSize;
                _cmdBuffer.GetTemporaryRT(
                    CRPShaderIDs._DirectionalShadowAtlas, 
                    atlasSize, atlasSize, 
                    24, 
                    FilterMode.Bilinear, 
                    RenderTextureFormat.Shadowmap);
                
                _cmdBuffer.SetRenderTarget(CRPShaderIDs._DirectionalShadowAtlas, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
                _cmdBuffer.ClearRenderTarget(true, false, Color.clear);

                int split = CalcSplitCount(_directionalShadowCount);
                int tileSize = atlasSize / split;

                //-- render shadow texture atlas; store shadow VP matrices
                for (int i = 0; i < _directionalShadowCount; ++i)
                {
                    RenderDirectionalShadow(i, split, tileSize);
                }
                
                _cmdBuffer.SetGlobalMatrixArray(CRPShaderIDs._DirectionalShadowMatrices, _directionalShadowMatrices);
            }
            _cmdBuffer.EndSample(ProfilingSampleNames.DirectionalShadows);
            
            ExecuteAndClearCmdBuffer();
        }

        private void RenderDirectionalShadow(int index, int split, int tileSize)
        {
            var shadow = _directionalShadows[index];
            
            _cullingResults.ComputeDirectionalShadowMatricesAndCullingPrimitives(
                shadow.visibleLightIndex,
                0, 1, Vector3.zero,
                tileSize,
                0f,
                out var viewMatrix,
                out var projMatrix,
                out var shadowSplitData);
            

            var shadowSettings = new ShadowDrawingSettings(_cullingResults, shadow.visibleLightIndex)
            {
                splitData = shadowSplitData
            };

            _directionalShadowMatrices[index] = ConvertToAtlasMatrix(projMatrix * viewMatrix, SetTileViewport(_cmdBuffer, index, split, tileSize), split);
            
            _cmdBuffer.SetViewProjectionMatrices(viewMatrix, projMatrix);
            _cmdBuffer.SetGlobalDepthBias(0f, 0.05f); // $$$
            ExecuteAndClearCmdBuffer();
            
            _context.DrawShadows(ref shadowSettings);
        }

        private static int CalcSplitCount(int directionalShadowCount)
        {
            return directionalShadowCount <= 1 ? 1 : 2; // up 2x2 atlas, 1..4 dir lights woth shadows
        }

        private static Vector2 SetTileViewport(CommandBuffer cmdBuffer, int index, int split, float tileSize)
        {
            var offset = new Vector2(index % split, index / split);
            cmdBuffer.SetViewport(new Rect(offset.x * tileSize, offset.y * tileSize, tileSize, tileSize));

            return offset;
        }
        
        Matrix4x4 ConvertToAtlasMatrix (Matrix4x4 m, Vector2 offset, int split) 
        {
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

        private void ExecuteAndClearCmdBuffer()
        {
            _context.ExecuteCommandBuffer(_cmdBuffer);
            _cmdBuffer.Clear();
        }
    }
}