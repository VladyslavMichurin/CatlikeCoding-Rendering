Shader "ShadersMadeByVlad/_Group2/1)PipeShader"
{
    Properties
    {
        _MainTex ("Tube Mat Texture", 2D) = "white" {}

        _MainTexPow ("Tube Tex Power", Range(0, 1)) = 1

        _Albedo ("Tube Color", Color) = (1,1,1,1)

        _EffectUVAdjustment ("Effect UV Adjustment", Vector) = (0,0,0,0)

        _GradientTex ("Gradient Texture", 2D) = "white" {}

        _GradientAlbedo ("Effect Color", Color) = (1,1,1,1)

        _YMod ("Y Mod", Range(0, 5)) = 1

        _AnimSpeed ("Anim Speed", Range(0, 3)) = 1

        _DisplacementForce ("Displacement Force", Vector) = (0,0,0,0)

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

                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;

                float2 effectUV : TEXCOORD1;
            };

            sampler2D _MainTex;

            sampler2D _GradientTex;
            float4 _GradientTex_ST;

            float _YMod, _MainTexPow;
            float _AnimSpeed;

            float4 _Albedo;
            float4 _GradientAlbedo;
            float3 _DisplacementForce;

            float4 _EffectUVAdjustment;
            
            float _Scale, _TimeScale;

            v2f vert (appdata v)
            {
                v2f o;

                float AnimTime = _Time.y * _AnimSpeed;

                o.uv = TRANSFORM_TEX(v.uv, _GradientTex);
                o.uv += AnimTime * _EffectUVAdjustment.zw;


                o.effectUV = v.uv + _EffectUVAdjustment.xy;
                o.effectUV.y += AnimTime;

                float xMod = tex2Dlod(_GradientTex, float4( float2( o.effectUV.y / _YMod,  o.effectUV.x), 0,1));

                float3 vert = v.vertex;

                vert.xyz += v.normal * (_DisplacementForce * xMod);

                o.vertex = UnityObjectToClipPos(vert);

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
                fixed4 finalColor = fixed4(1,1,1,1);
                fixed3 plasma = Plasma(i.uv);
                fixed4 tubeTex = tex2D(_MainTex, i.uv.xy + plasma.rg * 0.04);

                fixed4 gradientTex = tex2D(_GradientTex, float2(i.uv.y / _YMod, i.uv.x));

                finalColor = lerp((tubeTex * _MainTexPow) + (1 - _MainTexPow) * _Albedo,
                (tubeTex * _MainTexPow) + (1 - _MainTexPow) * _GradientAlbedo, gradientTex.y);

                return finalColor;
            }
            ENDCG
        }
    }
}
