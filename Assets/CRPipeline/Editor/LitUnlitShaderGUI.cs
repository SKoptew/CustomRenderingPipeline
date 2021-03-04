using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;

namespace CRP.Editor
{
    public class LitUnlitShaderGUI : ShaderGUI
    {
        private MaterialEditor     _editor;
        private Object[]           _materials;
        private MaterialProperty[] _properties;
        
        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            base.OnGUI(materialEditor, properties);

            _editor = materialEditor;
            _materials = materialEditor.targets;
            _properties = properties;
            
            OpaquePreset();
            AlphaClippingPreset();
            TransparencyFadePreset();
            TransparencyGlassPreset();
        }
        
        private bool Clipping         { set => SetProperty("_AlphaClipping", "USE_ALPHA_CLIPPING", value); }
        private bool PremultiplyAlpha { set => SetProperty("_PreMulAlpha",   "PREMULTIPLY_ALPHA",  value); }
        
        private BlendMode SrcBlend { set => SetProperty("_SrcBlend", (float) value); }
        private BlendMode DstBlend { set => SetProperty("_DstBlend", (float) value); }
        private bool      ZWrite   { set => SetProperty("_ZWrite", value ? 1f : 0f); }

        private RenderQueue RenderQueue
        {
            set
            {
                foreach (Material material in _materials)
                    material.renderQueue = (int) value;
            }
        }

        private bool HasProperty(string name) => FindProperty(name, _properties, false) != null;

        private void SetProperty(string name, string keyword, bool value)
        {
            if (SetProperty(name, value ? 1f : 0f))
                SetKeyword(keyword, value);
        }

        private bool SetProperty(string name, float value)
        {
            var property = FindProperty(name, _properties, false);
            if (property != null)
            {
                property.floatValue = value;
                return true;
            }

            return false;
        }

        private void SetKeyword(string keyword, bool enabled)
        {
            if (enabled)
            {
                foreach (Material material in _materials)
                    material.EnableKeyword(keyword);
            }
            else
            {
                foreach (Material material in _materials)
                    material.DisableKeyword(keyword);
            }
        }

        private bool PresetButton(string name)
        {
            if (GUILayout.Button(name))
            {
                _editor.RegisterPropertyChangeUndo(name);
                return true;
            }
            return false;
        }

        private void OpaquePreset()
        {
            if (PresetButton("Opaque"))
            {
                Clipping         = false;
                PremultiplyAlpha = false;
                SrcBlend         = BlendMode.One;
                DstBlend         = BlendMode.Zero;
                ZWrite           = true;
                RenderQueue      = RenderQueue.Geometry;
            }
        }
        
        private void AlphaClippingPreset()
        {
            if (PresetButton("AlphaClipping"))
            {
                Clipping         = true;
                PremultiplyAlpha = false;
                SrcBlend         = BlendMode.One;
                DstBlend         = BlendMode.Zero;
                ZWrite           = true;
                RenderQueue      = RenderQueue.AlphaTest;
            }
        }
        
        private void TransparencyFadePreset()
        {
            if (PresetButton("TransparencyFade"))
            {
                Clipping         = false;
                PremultiplyAlpha = false;
                SrcBlend         = BlendMode.SrcAlpha;
                DstBlend         = BlendMode.OneMinusSrcAlpha;
                ZWrite           = false;
                RenderQueue      = RenderQueue.Transparent;
            }
        }
        
        private void TransparencyGlassPreset()
        {
            if (HasProperty("_PreMulAlpha") && PresetButton("TransparencyGlass"))
            {
                Clipping         = false;
                PremultiplyAlpha = true;
                SrcBlend         = BlendMode.One;
                DstBlend         = BlendMode.OneMinusSrcAlpha;
                ZWrite           = false;
                RenderQueue      = RenderQueue.Transparent;
            }
        }
    }
}