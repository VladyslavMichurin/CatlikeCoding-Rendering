Shader "_MyShaders/_FunStuff/02)Gooch Shader"
{
    Properties
    {
       _MainTex ("Main Texture", 2D) = "white" {}
       _Tint ("Tint", Color) = (1, 1, 1, 1)

       _WarmColor ("Warm Color", Color) = (1,1,0,1)
       _CoolColor ("Cool Color", Color) = (0,0,1,1)

       _Alpha ("Alpha", Range(0, 1)) = 0.5
       _Beta ("Beta", Range(0, 1)) = 0.5

       _Smoothness ("Smoothness", Range(0.01,1)) = 0

       _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
       _OutlineThickness ("Outline Thickness", Range(0, 10.0)) = 1
    }
    SubShader
    {
       Tags 
        { 
            "RenderType"="Opaque"
            "Queue"="Geometry"
        }
        

        Pass
        {
            Name "Gooch"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityPBSLighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;

                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;

                 float3 normal : TEXCOORD1;
                 float3 viewDir : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float3 _Tint, _WarmColor, _CoolColor;

            float _Alpha, _Beta;

            float _Smoothness;

            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.normal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = normalize(WorldSpaceViewDir(v.vertex));

                return o;
            }

            float3 GetAlbedo(v2f i)
            {
                return tex2D(_MainTex, i.uv) * _Tint;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                i.normal = normalize(i.normal);

                float NdotL = dot(i.normal, _WorldSpaceLightPos0);
                float gooch = (1 + NdotL) / 2;

                float3 coolColor = (1 - gooch) * _CoolColor + _Alpha * GetAlbedo(i);
                float3 warmColor = gooch * _WarmColor + _Beta * GetAlbedo(i);
                float3 diffuse = coolColor + warmColor;

                float3 halfwayVec = normalize(_WorldSpaceLightPos0 + i.viewDir);
                float3 specular = DotClamped(halfwayVec, i.normal);
                specular = pow(specular, _Smoothness * 100);

                return float4(diffuse + specular, 1.0f);
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

            float _OutlineThickness;

            float4 _OutlineColor;

            v2f vert (appdata v)
            {
                v2f o;

                o.uv =  v.uv;
                o.normal = UnityObjectToWorldNormal(v.normal);

                float3 modifiedVertex = v.vertex + v.normal * _OutlineThickness / 10;

                o.vertex = UnityObjectToClipPos(modifiedVertex);

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
