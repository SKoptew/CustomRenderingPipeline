#ifndef _SHADOW_CASTER_PASS_COMMON_INCLUDED_
#define _SHADOW_CASTER_PASS_COMMON_INCLUDED_

Varyings ShadowCasterPassVertex(Attributes IN)
{
    Varyings OUT;
    
    UNITY_SETUP_INSTANCE_ID(IN);
    UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
    
    float3 positionWS = TransformObjectToWorld(IN.positionOS);
    OUT.positionCS    = TransformWorldToHClip(positionWS);

    // when rendering shadow casters for a dirLight, the near plane is moved forward as much as possible
    // this increased depth precision, but shadow casters that aren't in view of the camere can end up of the near plane
    // which causes them to get clipped. => clamp their positionCS to the near plane (=> flattening shadow casters)
    #if UNITY_REVERSED_Z
    OUT.positionCS.z = min(OUT.positionCS.z, OUT.positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #else
    OUT.positionCS.z = max(OUT.positionCS.z, OUT.positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #endif
    
    const float4 uv_ST = GetColorTexture_ST();
    OUT.UV = IN.UV * uv_ST.xy + uv_ST.zw;
    
    return OUT;    
}

void ShadowCasterPassFragment(Varyings IN)
{
    UNITY_SETUP_INSTANCE_ID(IN);
    
    const float alphaValue = SAMPLE_TEXTURE2D(_ColorTexture, sampler_ColorTexture, IN.UV).a * GetColor().a;    

    #ifdef _SHADOWS_CLIP
        clip(alphaValue - GetCutoff());
    #elif _SHADOWS_DITHER
        float dither = InterleavedGradientNoise(IN.positionCS.xy, 0);
        clip(alphaValue - dither);
    #endif
}

#endif