Shader "ShadersMadeByVlad/_Group2/3)Holofoil"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FoilTex ("Foil Texture", 2D) = "white" {}

        _Scale ("Plasma Scale", Range(0, 50)) = 20
        _TimeScale ("Time Scale", Range(0, 5)) = 1

        _FoilIntensity ("Foil Intensity", Range(0, 1)) = 1

        _ColorOne("Color One", Color) = (1,1,1,1)
        _ColorTwo("Color Two", Color) = (1,1,1,1)
        _ColorThree("Color Three", Color) = (1,1,1,1)

    }
    SubShader
    {
        Tags
        { 
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
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;

                float2 foilUV : TEXCOORD1;

                float3 viewDir : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _FoilTex;
            float4 _FoilTex_ST;

            float _Scale, _TimeScale;

            float _FoilIntensity;

            float4 _ColorOne, _ColorTwo, _ColorThree;

            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                o.foilUV = TRANSFORM_TEX(v.uv, _FoilTex);

                o.viewDir = WorldSpaceViewDir(v.vertex);

                return o;
            }

             float3 Plasma(float2 _UV)
            {
                _UV = _UV * _Scale - _Scale/2;

                float animTime = _Time.y * _TimeScale;

                float w1 = sin(_UV.x + animTime);
                float w2 = sin(_UV.y + animTime);
                float w3 = sin (_UV.x + _UV.y + animTime);
                float r = sin(sqrt(_UV.x * _UV.x + _UV.y * _UV.y) + animTime) * 2;

                float finalValue = w1 + w2 + w3 + r;

                float3 c1 = sin(finalValue * UNITY_PI) * _ColorOne;
                float3 c2 = cos(finalValue * UNITY_PI) * _ColorTwo;
                float3 c3 = sin(finalValue) * _ColorThree;

                return c1 + c2 + c3;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                fixed4 foilTex = tex2D(_FoilTex, i.foilUV);

                float2 newUV = i.viewDir.xy + foilTex.rg;
                float3 plasma = Plasma(newUV) * _FoilIntensity;

                fixed4 mainTex = tex2D(_MainTex, i.uv);

                return fixed4(mainTex.rgb + mainTex.rgb * plasma.rgb, 1);
            }
            ENDCG
        }
    }
}
