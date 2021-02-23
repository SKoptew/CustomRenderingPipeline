using UnityEngine;

public class PerObjectMaterialProperties : MonoBehaviour
{
    private static class ShaderID
    {
        public static readonly int _Color      = Shader.PropertyToID("_Color");
        public static readonly int _Metallic   = Shader.PropertyToID("_Metallic");
        public static readonly int _Smoothness = Shader.PropertyToID("_Smoothness");
    }

    private static MaterialPropertyBlock _block;

    public Color color = Color.white;
    
    [Range(0f,1f)] public float metallic = 0f;
    [Range(0f,1f)] public float smoothness = 0.5f;

    void Awake()
    {
        OnValidate(); // OnValidate doesn't get invoked in builds
    }
    
    void OnValidate()
    {
        if (_block == null)
            _block = new MaterialPropertyBlock();

        _block.SetColor(ShaderID._Color, color);
        _block.SetFloat(ShaderID._Metallic, metallic);
        _block.SetFloat(ShaderID._Smoothness, smoothness);
        GetComponent<Renderer>().SetPropertyBlock(_block);
    }
}
