Shader "MyNPR/Overlay_Shader"
{
    Properties
    {
        _MainTex ("Decal Texture", 2D) = "white" {}
        _BaseColor("BaseColor",Color)=(1,1,1,1)
    }
    SubShader
    {
        Tags {
            "Queue"="AlphaTest"
        }        

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _BaseColor;
        CBUFFER_END

        // 下面两句类似于 sampler2D _MainTex;
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        struct a2v{
            float4 positionOS:POSITION;            
            float2 texcoord:TEXCOORD;
        };

        struct v2f{
            float4 positionCS:SV_POSITION;
            float2 texcoord:TEXCOORD;
        };

        half Luminance(half3 nCol){
            return 0.2125 * nCol.r + 0.7154 * nCol.g + 0.0721 * nCol.b;
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
         
            v2f vert (a2v v)
            {
                v2f o;                
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);    // 类似于上面那句
                o.texcoord = v.texcoord;           
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {                
                half4 decalColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);

                if(Luminance(decalColor) > 0.3)
                    clip(-1);

                return decalColor;                
            }
            ENDHLSL
        }
    }
}
