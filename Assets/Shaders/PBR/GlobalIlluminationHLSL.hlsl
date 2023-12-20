#ifndef GLOBALILLUMINATION_INCLUDED
#define GLOBALILLUMINATION_INCLUDED

//env tex
TEXTURECUBE(_IrradianceMap);
SAMPLER(sampler_IrradianceMap);

// prefiltered Map
TEXTURECUBE(_IBLPrefilteredMap);
SAMPLER(sampler_IBLPrefilteredMap);

// brdf Texture(u:ndotv, v:roughness)
TEXTURE2D(_IBLBrdf);
SAMPLER(sampler_IBLBrdf);

float _MipLevel;

float3 fresnelSchlick(float cosTheta, float3 F0){
    float t = pow(1 - cosTheta, 5.0);
    return F0 + (1 - F0) * t;
}

float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness){
    float3 value = float3(1.0 - roughness, 1.0 - roughness, 1.0 - roughness);
    float result = F0 + (max(value, F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
    return result;
}

float DistributionGGX(float3 NdotH, float roughness)
{
    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH2 = NdotH * NdotH;

    float nom = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return nom / denom;
}

float NormalDistributionGGX(float NdotH, float roughness)
{
    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH2 = NdotH * NdotH;
    
    float nuor = a2;
    float deno = NdotH2 * (a2 - 1.0) + 1.0;
    deno = PI * deno * deno;

    return nuor / deno;
}


float GeometrySchlickGGX(float NdotV, float roughness)
{
    //直接光照的几何函数的粗糙度重投影为以下两行
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;

    float nuor = NdotV;
    float deno = NdotV * (1.0 - k) + k;

    return nuor / deno;
}

float GeometrySmith(float NdotV, float NdotL, float roughness)
{    
    float ggx1 = GeometrySchlickGGX(NdotV, roughness);
    float ggx2 = GeometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}

// PBR直接光部分(漫反射and镜面反射)
float3 PBR_DirectLit(float HdotV, float NdotH, float NdotV, float NdotL, float metalness, float roughness, float3 F0, float3 albedo, float3 lightCol){
    //Cook-Torrent BRDF(需要注意这个Cook-Torrent是用于计算高光的，直接光的漫反射直接用albedo贴图即可)
    float3 fresnel = fresnelSchlick(HdotV, F0);
    //float NDF = NormalDistributionGGX(NdotH, roughness);
    float NDF = NormalDistributionGGX(NdotH, roughness);
    float geo = GeometrySmith(NdotL, NdotV,  roughness);

    float3 nominator = NDF * geo * fresnel;
    float denominator = 4.0 * max(NdotV * NdotL, 0.0001);    
    float spec = nominator / denominator;

    float3 kS = fresnel;
    float3 kD = 1.0 - kS;  //漫反射项系数
    kD *= 1.0 - metalness;

    float3 directLit = (kD * albedo + spec) * NdotL * lightCol;

    return directLit;
}

// PBR间接光部分(漫反射and镜面反射)
float3 PBR_AmbientLit(float3 normalWS, float3 albedo, float3 viewDir, float3 reflectDir, float F0, float metallic, float roughness, float ao)
{
    float NdotV = max(0.0, dot(normalWS, viewDir));
    float3 fresnel_term = fresnelSchlickRoughness(NdotV, F0, roughness);
    
    float3 kS = fresnel_term;
    float3 kD = 1.0 - kS;
    kD *= 1.0 - metallic;
    
    // diffuse项
    float3 irradiance = SAMPLE_TEXTURECUBE(_IrradianceMap, sampler_IrradianceMap, normalWS).rgb;
    float3 diffuse = irradiance * albedo;
    
    // 采样预滤波贴图和BRDF LUT，并将这两者结合起来作为每一个Split-Sum近似，来获取IBL镜面反射部分
    const float MAX_REFLECTION_LOD = 4.0;
    
    // 预滤波贴图项
    float3 prefilteredColor = SAMPLE_TEXTURECUBE_LOD(_IBLPrefilteredMap, sampler_IBLPrefilteredMap, reflectDir, roughness * MAX_REFLECTION_LOD);
    //float3 prefilteredColor = SAMPLE_TEXTURECUBE_LOD(_IBLPrefilteredMap, sampler_IBLPrefilteredMap, reflectDir,  _MipLevel);
    
    // BRDF项
    float2 envBRDF = SAMPLE_TEXTURE2D_LOD(_IBLBrdf, sampler_IBLBrdf, float2(NdotV, roughness), 0.0).rg;
    
    // 预滤波贴图项和BRDF项结合起来就是Specular项
    float3 specular = prefilteredColor * (envBRDF.x * fresnel_term + envBRDF.y);

    float3 ambient = (kD * diffuse + specular) * ao;
    
    return ambient;
}

#endif