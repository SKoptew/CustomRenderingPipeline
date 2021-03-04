#ifndef _CRP_BRDF_INCLUDED_
#define _CRP_BRDF_INCLUDED_

struct BRDFData
{
    float3 diffuse;
    float3 specular;
    float  roughness;
};

float OneMinusReflectivity(float metallic)
{
    float range = 1.0 - DEFAULT_SPECULAR_VALUE;
    return range - metallic*range;
}

BRDFData GetBRDFData(SurfaceData surface, bool applyAlphaToDiffuse)
{
    BRDFData brdfData;
    brdfData.diffuse   = surface.color * OneMinusReflectivity(surface.metallic);        // metals have black diffuse component
    
    if (applyAlphaToDiffuse)
        brdfData.diffuse *= surface.alpha; // glass-like object. ONE, 1-SRCALPHA blending mode; specular lightint exists event on transparent parts - but diffuse must fade    
    
    brdfData.specular  = lerp(DEFAULT_SPECULAR_VALUE, surface.color, surface.metallic); // and colored reflective component
    brdfData.roughness = PerceptualSmoothnessToRoughness(surface.smoothness);
    
    return brdfData;
}

float SpecularStrength(SurfaceData surface, BRDFData brdf, LightData light) 
{
    const float  r2      = Square(brdf.roughness);
	const float3 H       = SafeNormalize(light.direction + surface.viewDirection);	
	const float  LdotH_2 = Square(saturate(dot(light.direction, H)));	
	const float  NdotH_2 = Square(saturate(dot(surface.normal, H)));
	const float  d_2     = Square(NdotH_2 * (r2 - 1.0) + 1.00001);
	
	const float normalization = brdf.roughness * 4.0 + 2.0;
	return r2 / (d_2 * max(0.1, LdotH_2) * normalization);
}

float3 DirectBRDF(SurfaceData surface, BRDFData brdf, LightData light)
{
    return SpecularStrength(surface, brdf, light) * brdf.specular + brdf.diffuse;
}

#endif