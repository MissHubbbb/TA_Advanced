Shader "CSTest/ParticleCSShader"
{    
    SubShader
    {
        Tags {
        "RenderPipeline" = "UniversalRenderPipeline"
        "RenderType"="Opaque" 
        }        

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"        
      
        struct v2f{
            float4 positionCS:SV_POSITION;
            float4 col : COLOR0;
        };

        struct ParticleData{
            float3 pos;
            float4 color;
        };
        ENDHLSL

        Pass
        {
            Tags{
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            StructuredBuffer<ParticleData> _particleDataBuffer;
         
            //SV_VertexID：在VertexShader中用它来作为传递进来的参数，代表顶点的下标。
            //我们有多少个粒子即有多少个顶点。顶点数据使用我们在CS中处理过的buffer。
            v2f vert (uint id : SV_VertexID)
            {
                v2f o;                
                o.positionCS = TransformObjectToHClip(float4(_particleDataBuffer[id].pos, 0)); 
                o.col = _particleDataBuffer[id].color;     
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                return i.col;   
            }
            ENDHLSL
        }
    }
}
