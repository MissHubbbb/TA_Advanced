Shader "MyPBR/IrradianceMap"
{
    Properties
    {
        _MainTex("HDR Env Map", CUBE) = "white" {}
    }
    SubShader
    {
        Tags {
        "RenderPipeline" = "UniversalRenderPipeline"
        "RenderType"="Opaque" 
        }        

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        
        CBUFFER_END

        const float2 invAtan = float2(0.1591, 0.3183);

        float2 SampleSphericalMap(float3 v){
            float2 uv = float2(atan2(v.z, v.x), asin(v.y));
            uv *= invAtan;
            uv += 0.5;
            return uv;
        }

        TEXTURECUBE(_MainTex);
        SAMPLER(sampler_MainTex);

        struct a2v{
            float4 positionOS:POSITION;            
        };

        struct v2f{
            float4 positionCS:SV_POSITION;
            float3 worldPos:TEXCOORD0;            
        };

        v2f vert (a2v v)
        {
            v2f o;          
            o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
            o.worldPos = v.positionOS.xyz;
            return o;
        }

        float4 frag (v2f i) : SV_Target
        {            
            float3 color = SAMPLE_TEXTURECUBE(_MainTex, sampler_MainTex, i.worldPos).rgb;
            return float4(color, 1.0);
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
