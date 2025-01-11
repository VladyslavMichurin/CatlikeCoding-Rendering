Shader "_MyShaders/_FunStuff/01)Manga Shader Attempt"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)

        _ShadowColor ("Shadow Color", Color) = (0, 0, 0, 1)
        _ShadowPercent ("Shadow Persent", range(0, 1)) = 0.1

        _HighlightColor ("Highlight Color", Color) = (1, 1, 1, 1)
        _HighlightPercent ("Highlight Persent", range(0, 1)) = 0.1

        [NoScaleOffset] _NormalMap ("Normals", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Range(0, 2)) = 0.2

        _Test ("Test", 2D) = "white" {}

        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        _OutlineThickness ("Outline Thickness", Range(0, 10.0)) = 1
        _OutlineNoiseTex ("Outline Noise Texture", 2D) = "white" {}
        _OutlineNoiseAmmount ("Outline Noise Ammount", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque"
        }

        Pass
        {
            Name "Base Color"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityPBSLighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;

                float3 normal : NORMAL;
                float4 tangent : TEXCOORD2;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 uv : TEXCOORD0;

                float3 normal : TEXCOORD1;
                float4 tangent : TEXCOORD2;
            };

            float4 _BaseColor, _ShadowColor, _HighlightColor;

            float _ShadowPercent, _HighlightPercent;

            sampler2D _NormalMap, _Test;
            float4 _NormalMap_ST, _Test_ST;
            float _BumpScale;

            v2f vert (appdata v)
            {
                v2f o;

                o.uv.xy = v.uv.xy;
                o.uv.zw = TRANSFORM_TEX(v.uv.zw, _Test);
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

                return o;
            }

            float3 CreateBinormal(float3 _normal, float3 _tangent, float _binormalSign)
            {
                return cross(_normal, _tangent) * _binormalSign * unity_WorldTransformParams.w;
            }

            void InitializeFragmentNormal(inout v2f i)
            {
                float3 normalMap = UnpackScaleNormal(tex2D(_NormalMap, i.uv), _BumpScale);
                float binormal = CreateBinormal(i.normal, i.tangent, i.tangent.w);

                i.normal = normalize(
                    normalMap.x * i.tangent +
                    normalMap.y * binormal +
                    normalMap.z * i.normal
                    );
            }

            float4 ManageShadowColor(v2f i)
            {
                

                return _ShadowColor;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                InitializeFragmentNormal(i);
                
                float NdotL = dot(i.normal, _WorldSpaceLightPos0);
                float remapedNdotL = (NdotL + 1) / 2;

                float shadowAmmount = smoothstep(0, _ShadowPercent / 2, remapedNdotL);
                float shadowIntensity = smoothstep(0.99, 1, shadowAmmount);
                float4 litColor = lerp(ManageShadowColor(i), _BaseColor, shadowIntensity);

                float highlightAmmount = smoothstep(1 - _HighlightPercent, 1, NdotL);
                float highlightIntensity = smoothstep(0, 0.01, highlightAmmount);
                float4 finalColor = lerp(litColor, _HighlightColor, highlightIntensity);

                return finalColor;
            }
            ENDCG
        }

        Pass
        {
            Name "Outline"

            ZWrite Off
            Cull Front
            

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

             #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;

                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;

                float3 normal : TEXCOORD1;
            };

            sampler2D _OutlineNoiseTex;
            float4 _OutlineNoiseTex_ST, _OutlineColor;
            float _OutlineThickness, _OutlineNoiseAmmount, _test;


            v2f vert (appdata v)
            {
                v2f o;

                o.uv =  TRANSFORM_TEX(v.uv, _OutlineNoiseTex);
                o.normal = UnityObjectToWorldNormal(v.normal);

                float3 noiseTex = tex2Dlod(_OutlineNoiseTex, float4(o.uv, 0,0));
                float3 modifiedNormals = v.normal + v.normal * noiseTex;

                float3 modifiedVertex = v.vertex + v.normal * _OutlineThickness / 10;
                float3 modifiedVertex2 = v.vertex + modifiedNormals * _OutlineThickness / 10;

                float3 finalVert = lerp(modifiedVertex, modifiedVertex2, _OutlineNoiseAmmount);

                o.vertex = UnityObjectToClipPos(finalVert);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        }
    }
}
