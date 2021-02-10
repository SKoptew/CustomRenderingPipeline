using UnityEngine;

public class PerObjectMaterialProperties : MonoBehaviour
{
    private static readonly int ShaderIdColor = Shader.PropertyToID("_Color");

    private static MaterialPropertyBlock _block;

    public Color color = Color.white;

    void Awake()
    {
        OnValidate(); // OnValidate doesn't get invoked in builds
    }
    
    void OnValidate()
    {
        if (_block == null)
            _block = new MaterialPropertyBlock();

        _block.SetColor(ShaderIdColor, color);
        GetComponent<Renderer>().SetPropertyBlock(_block);
    }
}
