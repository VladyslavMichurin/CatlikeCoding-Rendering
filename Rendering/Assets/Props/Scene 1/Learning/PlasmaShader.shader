Shader "ShadersMadeByVlad/_Group2/2)PlasmaShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _Scale ("Plasma Scale", Range(0, 50)) = 1
        _TimeScale ("Time Scale", Range(0, 5)) = 1
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
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _Scale, _TimeScale;

            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            float3 Plasma(float2 _UV)
            {
                _UV = _UV * _Scale - _Scale/2;

                float animTime = _Time.y * _TimeScale;

                float w1 = sin(_UV.x + animTime);
                float w2 = sin(_UV.y + animTime) * 0.5;
                float w3 = sin (_UV.x + _UV.y + animTime);
                float r = sin(sqrt(_UV.x * _UV.x + _UV.y * _UV.y) + animTime);

                float finalValue = w1 + w2 + w3 + r;

                float3 finalWave =  float3(sin(finalValue * UNITY_PI), cos(finalValue * UNITY_PI), 0);
                finalWave = finalWave * 0.5 + 0.5;

                return finalWave;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 plasma = Plasma(i.uv);
                fixed4 mainTex = tex2D(_MainTex, i.uv + plasma.rg * 0.01);

                return fixed4(mainTex.rgb, 1);
            }
            ENDCG
        }
    }
}
