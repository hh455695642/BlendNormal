Shader "Unlit/NormalTest"
{
    Properties
    {
        [MaiColor] _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        [MaiTexture] _BaseMap ("Base Map", 2D) = "white" { }
        [Normal] _NormalMap ("Normal Map", 2D) = "bump" { }
        [Normal] _DetailNormalMap ("Detail Normal Map", 2D) = "bump" { }
        _NormalStrength("Normal Strength",float) =1
    }

    SubShader
    {
        
        Tags { "RenderType" = "Opaque" "RenderPipelie" = "UniversalPipelie" }

        Pass
        {
            
            Name "ForwardUnlit"
            
            HLSLPROGRAM
            
            #pragma vertex vert            
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
  
            struct Attributes
            {              
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct Varyigs
            {           
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 positionVS : TEXCOORD1;
                float2 uv : TEXCOORD2;
                float3 normalWS : TEXCOORD3;
                float3 tangentWS : TEXCOORD4;
                float3 bitangentWS : TEXCOORD5;
                float2 detailNormaluv : TEXCOORD6;
            };
            
            TEXTURE2D(_BaseMap);          SAMPLER(sampler_BaseMap);
            TEXTURE2D(_NormalMap);          SAMPLER(sampler_NormalMap);
            TEXTURE2D(_DetailNormalMap);          SAMPLER(sampler_DetailNormalMap);

            CBUFFER_START(UnityPerMaterial)               
                half4 _BaseColor;
                float4 _BaseMap_ST;
                float4 _NormalMap_ST;
                float4 _DetailNormalMap_ST;
                float _NormalStrength;
            CBUFFER_END

            
            Varyigs vert(Attributes v)
            {
               
                Varyigs o;
            
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionHCS = vertexInput.positionCS;
                o.positionWS = vertexInput.positionWS;
                o.positionVS = vertexInput.positionVS;

                VertexNormalInputs vertexNormalInputs = GetVertexNormalInputs(v.normalOS,v.tangentOS);
                o.normalWS = vertexNormalInputs.normalWS;               
                o.bitangentWS= vertexNormalInputs.bitangentWS;
                o.tangentWS = vertexNormalInputs.tangentWS;
                
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                o.detailNormaluv = TRANSFORM_TEX(v.uv, _DetailNormalMap);
                
                return o;
            }

            half4 frag(Varyigs i) : SV_Target
            {
                Light mainLight = GetMainLight(TransformWorldToShadowCoord(i.positionWS));
                half3 lightDir = mainLight.direction;

                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                
                half3 NormalMap = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv), _NormalStrength) ;
                half3 DetailNormalMap = UnpackNormalScale(SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailNormalMap, i.detailNormaluv),_NormalStrength) ;
                //法线混合
                //half3 Normal =normalize(NormalMap + DetailNormalMap);

                // NormalMap= (NormalMap+1)/2;
                // DetailNormalMap = (DetailNormalMap+1)/2;
                // half3 Normal = NormalMap < 0.5 ? 2 * NormalMap * DetailNormalMap : 1 - 2 * (1 - NormalMap) * (1 - DetailNormalMap);
                // Normal = normalize(Normal*2-1);

                //half3 Normal = normalize(float3(NormalMap.xy / DetailNormalMap.z + DetailNormalMap.xy / NormalMap.z, NormalMap.z * DetailNormalMap.z));

                //half3 Normal = normalize(float3(NormalMap.xy  + DetailNormalMap.xy, NormalMap.z * DetailNormalMap.z));

                //half3 Normal = normalize(float3(NormalMap.xy  + DetailNormalMap.xy, NormalMap.z));

                NormalMap = half3(NormalMap.xy, NormalMap.z + 1);
                DetailNormalMap = half3(-DetailNormalMap.xy, DetailNormalMap.z);
                //half3 Normal = NormalMap * dot(NormalMap, DetailNormalMap) - DetailNormalMap * NormalMap.z;
                half3 Normal = normalize(NormalMap / NormalMap.z * dot(NormalMap, DetailNormalMap)  - DetailNormalMap);
                //世界空间法线贴图
                half3x3 tangentToWorld = half3x3(i.tangentWS.xyz, i.bitangentWS, i.normalWS.xyz);
                half3 normalWS = normalize(TransformTangentToWorld(Normal, tangentToWorld)) ;


                half3 c = dot(normalWS, lightDir) ;


                color *= _BaseColor;
                return half4(c,1);
            }
            ENDHLSL
        }
    }
}
