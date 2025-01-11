Shader "ShadersMadeByVlad/3)TryingToUnderstandNormal"
{
    Properties
    {
        [MainTexture] _MainTex ("Albedo", 2D) = "white" {}

        [NoScaleOffset] _NormalTex ("Normal Map", 2D) = "bump" {}
        _NormalStrenght ("Normal Map Strenght", Range(0, 1)) = 1

        [NoScaleOffset] _RoughnessTex ("Normal Map", 2D) = "bump" {}
        _RoughnessStrenght ("Rougness Strenght", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags { 

        "LightMode" = "UniversalForward"
        "RenderType"="Opaque" 
        
        }
     

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex    : POSITION;
                float2 uv        : TEXCOORD0;

                float3 normal    : NORMAL;
                float3 tangent   : TANGENT;
            };

            struct v2f
            {
                float4 vertex    : SV_POSITION;
                float2 uv        : TEXCOORD0;
                    
                float3 tbn[3]    : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _NormalTex;
            float4 _NormalTex_ST;
            float _NormalStrenght;

            sampler2D _RoughnessTex;
            float4 _RoughnessTex_ST;
            float _RoughnessStrenght;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                float3 normal = UnityObjectToWorldNormal(v.normal);
                float3 tangent = UnityObjectToWorldNormal(v.tangent);
                float3 bitangent = cross(tangent, normal);

                o.tbn[0] = tangent;
                o.tbn[1] = bitangent;
                o.tbn[2] = normal;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 finalColor = tex2D(_MainTex, i.uv);

                // adding normal map support and light
                float4 tangentNormal = tex2D(_NormalTex, i.uv) * 2 - 1;
                float3 worldNormal = 
                float3(tangentNormal.r * i.tbn[0] + tangentNormal.g * i.tbn[1] + tangentNormal.b * i.tbn[2]);

                float diff = max(dot(i.tbn[2], _WorldSpaceLightPos0), 0.0);
                float4 diffuseLight = diff * float4(1,1,1,1);

                 float4 finalNormal = _NormalStrenght * dot(worldNormal, _WorldSpaceLightPos0);
                 finalNormal += (1 - _NormalStrenght) * diffuseLight;

                 finalColor *= finalNormal; 

                finalColor = saturate(finalColor);
                //

                // adding rougness Map
                float4 rougnessAlbedo = tex2D(_RoughnessTex, i.uv);

                float4 reflectColor = _RoughnessStrenght * float4(1,0,0,1);
                reflectColor += (1 - _RoughnessStrenght) *  float4(1,1,1,1);

                float4 finalRougness = rougnessAlbedo * reflectColor;

                finalColor *= finalRougness; 

                //

                return finalColor;
            }
            ENDCG
        }
    }
}
