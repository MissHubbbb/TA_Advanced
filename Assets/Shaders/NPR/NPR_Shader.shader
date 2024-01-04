Shader "MyNPR/NPR_Shader"
{
    Properties
    {
        _MainTex ("Base Texture", 2D) = "white" {}        
        _SssTex("SSS Texture", 2D) = "white" {}
        _LightMap("LightMap", 2D) = "white" {}        
        _IlmTex("ilm Texture", 2D) = "white" {}
        _DetailTex("Detail Texture", 2D) = "white" {}

        _ShadowIntensity("Shadow Intensity", range(0, 1)) = 0.7
        _DetailIntensity("Detail Intensity", range(0,1)) = 1    //线条磨损强度
        _RampOffset("Ramp Offset", range(0, 1)) = 0     //ramp偏移
        _Threshold0("Light Threshold", range(0, 1)) = 0.5   //光照边缘范围

        _SpecularPower("Specular Power",float) = 15     //高光次幂
        _SpecularIntensity("Specular Intensity", range(0, 1)) = 1       //高光强度

        _LayerMaskStep("Body Region Divede", range(0, 255)) = 35    //身体区域切分(用来处理部位分割问题，例如膝盖处高光
        _BodySpecularWidth("Body Specular Width", range(0,1)) = 0.5  //身体的高光宽度
        _BodySpecularIntensity("Body Specular Intensity", range(0,1)) = 0.8     //身体的高光强度
        _HeadSpecularWidth("Head Specular Width", range(0,1)) = 0.5     //头部的高光宽度
        _HeadSpecularIntensity("Head Specular Intensity",Range(0,1)) = 0.8  //头部的高光强度
        _MetallicStepSpecularWidth("_MetallicStepSpecularWidth", range(0,1)) = 0.5      //金属的高光宽度
        _MetallicStepSpecularIntensity("_MetallicStepSpecularIntensity",Range(0,1)) = 0.8       //金属的高光强度

        _RimWidth("Rim Width",range(0, 1)) = 0.5    //边缘光宽度
        _RimIntensity("Rim Intensity", range(0, 1)) = 0.7   //边缘光强度

        _OutlineWidth("Outline Width",range(0, 1)) = 0.001
        _OutlineColor("Outline Color",Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags {
        "RenderPipeline" = "UniversalRenderPipeline"
        "RenderType"="Opaque" 
        }        

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half _ShadowIntensity;
        half _DetailIntensity;
        half _RampOffset;
        half _Threshold0;

        float _SpecularPower;
        half _SpecularIntensity;

        float _LayerMaskStep;
        half _BodySpecularWidth;
        half _BodySpecularIntensity;
        half _HeadSpecularWidth;
        half _HeadSpecularIntensity;
        half _MetallicStepSpecularWidth;
        half _MetallicStepSpecularIntensity;

        half _RimWidth;
        half _RimIntensity;

        half _OutlineWidth;
        half4 _OutlineColor;        
        CBUFFER_END
        
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        
        TEXTURE2D(_SssTex);
        SAMPLER(sampler_SssTex);

        TEXTURE2D(_LightMap);
        SAMPLER(sampler_LightMap);
        
        TEXTURE2D(_IlmTex);
        SAMPLER(sampler_IlmTex);

        TEXTURE2D(_DetailTex);
        SAMPLER(sampler_DetailTex);            
        
        ENDHLSL

        Pass
        {
            Tags{
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct a2v{
                float4 positionOS:POSITION;
                float3 normalOS:NORMAL;            
                float2 texcoord:TEXCOORD;
                half4 vertColor:COLOR;  //模型顶点色
            };

            struct v2f{
                float4 positionCS:SV_POSITION;
                half3 normalWS:TEXCOORD0;            
                half3 positionWS:TEXCOORD2;
                float4 texcoord:TEXCOORD3;
                half4 vertColor:TEXCOORD4;
            };     
         
            v2f vert (a2v v)
            {
                v2f o;
                //o.vertex = UnityObjectToClipPos(v.vertex);
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.texcoord.xy = TRANSFORM_TEX(v.texcoord, _MainTex);    
                o.texcoord.zw = v.texcoord;

                //vertex color
                //r:AO常暗部分
                //g:用来区分身体的部位，比如脸部=88。
                //b:描边粗细
                //a:没用到的通道
                o.vertColor = v.vertColor;
                
                //法线处理
                float3 normalWS = TransformObjectToWorldNormal(v.normalOS);                         
                o.normalWS = normalWS;                
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float3 positionWS = i.positionWS;
                
                //法线
                i.normalWS.xyz = normalize(i.normalWS.xyz);
                
                //场景数据           
                Light myLight = GetMainLight();            
                half3 lightDir = normalize(myLight.direction);    //光照方向
                half3 lightCol = myLight.color;
                half3 viewDir = normalize(GetCameraPositionWS() - positionWS);
                half3 reflectDir = normalize(reflect(-lightDir, i.normalWS.xyz));

                //其他向量
                half3 halfDir = normalize(viewDir + lightDir);

                //各种点乘结果
                half NdotL = max(dot(i.normalWS.xyz, lightDir), 0.0);                
                NdotL = NdotL * 0.5 + 0.5;      //half-lambert
                half NdotV = max(dot(i.normalWS.xyz, viewDir), 0.0);
                half NdotH = max(dot(i.normalWS.xyz, halfDir), 0.0);

                //基础颜色贴图
                // base texture
                half3 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord.xy).rgb;
                half baseColorA = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord.xy).a;

                //LightMap
                half4 LightMapColor = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, i.texcoord.xy);

                //sss texture
                half3 sssColor = SAMPLE_TEXTURE2D(_SssTex, sampler_SssTex, i.texcoord.xy).rgb;
                half3 sssColorA = SAMPLE_TEXTURE2D(_SssTex, sampler_SssTex, i.texcoord.xy).a;

                //detail texture 磨损线条贴图
                half4 detailTex = SAMPLE_TEXTURE2D(_DetailTex, sampler_DetailTex, i.texcoord.zw);

                //ilm Texture
                half4 ilmColor = SAMPLE_TEXTURE2D(_IlmTex, sampler_IlmTex, i.texcoord.xy);
                half specLayerMask = ilmColor.r;       //高光材质类型（通用、金属、皮革）
                half shadowWeight = ilmColor.g;        //Ramp偏移值
                half specIntensityMask = ilmColor.b;   //高光强度类型Mask（无高光、裁边高光、Blinn-Phong高光）
                half benCunLine = ilmColor.a;          // 本村线/内描线

                // [_IlmTex.g]-用来设置阴影偏移 [i.vertColor.r]-用来控制阴影强度
                half shadowControl = saturate(step(_Threshold0, (NdotL + shadowWeight + _RampOffset) * i.vertColor.r));                
                // [i.vertColor.g]-用来区分物体部位              
                
                //漫反射(间接光照)
                baseColor *= benCunLine;        //叠加内描线
                baseColor = lerp(baseColor, baseColor * detailTex.xyz, _DetailIntensity);   //线条磨损的调节
                half3 diffuse = lerp(sssColor, baseColor, (1 - _ShadowIntensity));      //阴影调节
                diffuse = lerp(diffuse, baseColor, shadowControl) * lightCol;             //依旧是阴影调节
                half3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * baseColor;

                if(i.vertColor.g >= 0.22 && i.vertColor.g < 0.26){
                    diffuse = diffuse + ambient;
                }

                //高光(直接光照)
                half3 specular = half3(0.0,0.0,0.0);
                specular = pow(NdotH, _SpecularPower) * _SpecularIntensity * baseColor;
                specular = max(0.0, specular);                
                // LayerMask
                // [0,10] 普通 无边缘光  
                // (10,145]皮革 皮肤 有边缘光
                // (145,200] 头发 有边缘光
                // (200,255] 金属 裁剪高光 无边缘光
                half linearMask = pow(specLayerMask, 1/2.2);    //转换到线性空间
                half layerMask = linearMask * 255;      //将范围从[0, 1]转换到[0, 255]

                half specIntensity = 0.0;

                //皮革边缘处 大腿皮肤 裁边高光
                if(layerMask >= 10 && layerMask < _LayerMaskStep){
                    specIntensity = pow(specIntensityMask, 1/2.2) * 255;      //范围转换为[0,255]
                    half stepSpecularMask = float(specIntensity > 0 && specIntensity <= 140);
                    half3 bodySpecular = saturate(step(1-NdotV, _BodySpecularWidth)) * _BodySpecularIntensity * baseColor;
                    specular = lerp(specular, bodySpecular, stepSpecularMask);
                }
                //头发 有边缘光
                if(layerMask > 145 && layerMask <= 200){
                    half specIntensity = pow(specIntensityMask, 1/2.2) * 255;      //围转换为[0,255]
                    half stepSpecularMask = float(specIntensity > 140 && specIntensity <= 255);
                    half3 hairSpecular = saturate(step(1-_HeadSpecularWidth, NdotV)) * _HeadSpecularIntensity * baseColor;
                    specular = lerp(specular, hairSpecular, stepSpecularMask);
                }
                //金属 裁剪高光 无边缘光
                if(layerMask > 200){                    
                    half3 metallicStepSpecular = step(NdotL, _MetallicStepSpecularWidth) * _MetallicStepSpecularIntensity * baseColor;
                    specular += metallicStepSpecular;
                }
                specular *= lightCol;

                //边缘光(间接光照)
                half rimWidthControl = step(1 - _RimWidth, (1 - NdotV));
                half3 rim = rimWidthControl * _RimIntensity * baseColor;
                rim = lerp(0, rim, shadowControl);
                rim = max(0.0, rim);
                rim *= lightCol;

                return half4(diffuse + specular + rim + ambient, 1.0);                
                //return half4(i.vertColor.a, i.vertColor.a, i.vertColor.a, 1.0);
                //return half4(specIntensityMask,specIntensityMask,specIntensityMask, 1.0);
            }
            ENDHLSL
        }

        Pass{
            Name "Outline"
            cull front

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag            

            struct a2v_Outline{
                float4 positionOS:POSITION;
                float3 normalOS:NORMAL;
                float2 texcoord:TEXCOORD0;
                float4 vertColor:COLOR;
                float4 tangent:TANGENT;
            };

            struct v2f_Outline{
                float4 positionCS:SV_POSITION;
            };

            half3 TransformViewToProjection (half3 v) {
                return mul((float3x3)UNITY_MATRIX_P, v);
            }

            v2f_Outline vert(a2v_Outline v){
                v2f_Outline o;                
                float4 posCS = TransformObjectToHClip(v.positionOS);
                
                //这里做法线转换的原因是为了不管从什么角度看描边，描边的粗细宽度都一致
                //(因为需要在NDC空间乘回原本做的透视除法的w)
                //将法线转换到view空间
                //half3 normalVS = mul((float3x3)UNITY_MATRIX_IT_MV, v.normalOS.xyz); 
                half3 normalVS = mul((float3x3)UNITY_MATRIX_IT_MV, v.tangent.xyz); 
                //将法线转换到NDC空间
                float3 normalNDC = normalize(TransformViewToProjection(normalVS.xyz)) * posCS.w;     
                
                //unity默认直接用NDC空间距离外扩，不能适配宽屏窗口，会导致描边上下细，两边宽，所以需要修正宽高比
                //将近裁剪面右上角位置的顶点变换到观察空间
                //_ProjectionParams float4
                //x=1.0(或-1.0，如果正在使用一个翻转的投影矩阵进行渲染)
                //y=Near
                //z=Far
                //w=1.0+1.0/Far
                //其中Near和Far分别是近裁剪平面和远裁剪平面离摄像机的距离。
                float4 nearUpperRight = mul(unity_CameraInvProjection, float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));
                half aspect = abs(nearUpperRight.y / nearUpperRight.x);     //求得屏幕宽高比
                normalNDC.x *= aspect;

                posCS.xy += 0.01 * _OutlineWidth * normalNDC.xy * v.vertColor.b;
                o.positionCS = posCS;
                
                return o;
            }

            half4 frag(v2f_Outline i):SV_Target
            {
                    return _OutlineColor;
            }
            ENDHLSL
        }
    }
}
