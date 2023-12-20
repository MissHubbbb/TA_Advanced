Shader "MyPBR/PBR_Shader"
{
    Properties
    {
        //_MainTex ("Texture", 2D) = "white" {}
        _AlbedoMap("Albedo", 2D) = "white" {}
        _NormalMap("Normal", 2D) = "bump" {}
        _MetallicMap("Metallic", 2D) = "white" {}
        _RoughnessMap("Roughness", 2D) = "white" {}
        _AOMap("AO", 2d) = "white" {}        

        _IrradianceMap("IrradianceMap", CUBE) = "white"{}
        _IBLPrefilteredMap("IBL_PrefilteredMap", CUBE) = "white"{}
        _IBLBrdf("IBL_BRDF", 2D) = "white" {}
        
        _BaseColor("Base Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Brightness("Brightness", Range(0, 10.0)) = 1.0
        _MetallicFactor("Metallic Factor", Range(0, 10)) = 0.5
        _RoughnessFactor("Roughness Factor", Range(1.0, 3.0)) = 1.6
        _MipLevel("Mipmap Level", range(0.0, 7.0)) = 1.0
    }

    SubShader
    {
        Tags {
        "RenderPipeline" = "UniversalRenderPipeline"
        "RenderType"="Opaque" 
        }        

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "GlobalIlluminationHLSL.hlsl"
        CBUFFER_START(UnityPerMaterial)
        float4 _AlbedoMap_ST;
        float4 _NormalMap_ST;
        float4 _MetallicMap_ST;
        float4 _RoughnessMap_ST;
        float4 _AOMap_ST;        

        float4 _BaseColor;
        float _Brightness;
        float _MetallicFactor;
        float _RoughnessFactor;
        CBUFFER_END

        // 下面两句类似于 sampler2D _MainTex;
        TEXTURE2D(_AlbedoMap);
        SAMPLER(sampler_AlbedoMap);

        TEXTURE2D(_NormalMap);
        SAMPLER(sampler_NormalMap);

        TEXTURE2D(_MetallicMap);
        SAMPLER(sampler_MetallicMap);

        TEXTURE2D(_RoughnessMap);
        SAMPLER(sampler_RoughnessMap);

        TEXTURE2D(_AOMap);
        SAMPLER(sampler_AOMap);        

        struct a2v{
            float4 positionOS:POSITION;
            float3 normalOS:NORMAL;
            float4 tangentOS:TANGENT;
            float2 texcoord:TEXCOORD;
        };

        struct v2f{
            float4 positionCS:SV_POSITION;
            float3 normalWS:TEXCOORD0;
            float4 tangentWS:TEXCOORD1;
            float3 positionWS:TEXCOORD2;
            float2 texcoord:TEXCOORD3;
        };

        v2f vert (a2v v)
        {
            v2f o;            
            o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
            o.texcoord = v.texcoord;

            //以下几行，其实是GetVertexNormalInputs()函数中的实现方法
            float3 normalWS = TransformObjectToWorldNormal(v.normalOS);
            float3 tangentWS = TransformObjectToWorldDir(v.tangentOS.xyz);            
            float sign = v.tangentOS.w * GetOddNegativeScale();          
            o.normalWS = normalWS;
            o.tangentWS = float4(tangentWS, sign);
            o.positionWS = TransformObjectToWorld(v.positionOS.xyz);        
            return o;
        }

        float4 frag (v2f i) : SV_Target
        {   
            float3 positionWS = i.positionWS;

            //基本材质数据
            float3 albedo = SAMPLE_TEXTURE2D(_AlbedoMap, sampler_AlbedoMap, i.texcoord);
            albedo *= _BaseColor.rgb;
            float metallic = SAMPLE_TEXTURE2D(_MetallicMap, sampler_MetallicMap, i.texcoord).x;
            metallic *= _MetallicFactor;
            float roughness = SAMPLE_TEXTURE2D(_RoughnessMap, sampler_RoughnessMap, i.texcoord);
            roughness *= _RoughnessFactor;
            float ao = SAMPLE_TEXTURE2D(_AOMap, sampler_AOMap, i.texcoord);

            //采样法线贴图，取得切线空间的法线
            float4 normalColor = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.texcoord);
            float3 normalTS = UnpackNormalScale(normalColor, 1.0);

            //求出法线矩阵
            i.normalWS.xyz = normalize(i.normalWS.xyz);
            i.tangentWS.xyz = normalize(i.tangentWS.xyz);
            float sign = i.tangentWS.w;
            float3 bitangentWS = normalize(cross(i.normalWS, i.tangentWS) * sign);
            float3x3 TBN_TangentToWorld = float3x3(i.tangentWS.xyz, bitangentWS.xyz, i.normalWS.xyz);
            //TBN_TangentToWorld = transpose(TBN_TangentToWorld);

            //将法线从切线空间转换到世界空间,并归一化
            float3 normalWS = TransformTangentToWorld(normalTS, TBN_TangentToWorld);
            normalWS = NormalizeNormalPerPixel(normalWS);

            //场景数据            
            Light myLight = GetMainLight();            
            float3 lightDir = normalize(myLight.direction);    //光源方向            
            float3 lightCol = myLight.color;
            float3 viewDir = normalize(GetCameraPositionWS() - positionWS);
            float3 reflectDir = normalize(reflect(-lightDir, normalWS));

            //一些其他向量
            float3 halfDir = normalize(viewDir + lightDir);

            //点乘结果
            float NdotH = max(dot(normalWS, halfDir), 0.0);     
            float NdotV = max(dot(normalWS, viewDir), 0.0);
            float NdotL = max(dot(normalWS, lightDir), 0.0);
            float HdotV = max(dot(halfDir, viewDir), 0.0);            

            //基础反射率
            float3 F0 = lerp(0.04, albedo.rgb, metallic);       //TODO:其他人用的lerp，暂时没尝试区别

            //TODO: 求直接光照
            float3 directLit = PBR_DirectLit(HdotV, NdotH, NdotV, NdotL, metallic, roughness, F0, albedo, lightCol);
            directLit *= _Brightness;
            
            //TODO: 求间接光照
            float3 ambientLit = PBR_AmbientLit(normalWS, albedo, viewDir, reflectDir, F0, metallic, roughness, ao);

            //TODO: 所有光照都加起来，全局光照
            float3 globalLit = directLit + ambientLit;
            //float3 globalLit = directLit;

            return float4(globalLit, 1.0);                
            //return float4(HdotV, HdotV, HdotV, 1.0);
        }
        ENDHLSL

        Pass
        {
            Tags{
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM            
            #pragma vertex vert
            #pragma fragment frag        
            
            ENDHLSL
        }
    }
}
