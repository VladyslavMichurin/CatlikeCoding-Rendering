Shader "ShadersMadeByVlad/9)RadialRevealShader"
{
    Properties
    {
        _FrontTex ("Front Texture", 2D) = "white" {}
        _BackTex ("Back Texture", 2D) = "white" {}

        _Rotation ("Rotation", Range(0, 10)) = 0
        _Reveal ("Reveal", Range(0,1)) = 0
        _Smoothness ("Smoothness", Range(0,1)) = 0
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
                float4 uv : TEXCOORD0;
                float2 rotUV : TEXCOORD1;
            };

            sampler2D _FrontTex;
            float4 _FrontTex_ST;

            sampler2D _BackTex;
            float4 _BackTex_ST;

            float _Rotation, _Reveal, _Smoothness;

            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _FrontTex);
                o.uv.zw = TRANSFORM_TEX(v.uv, _BackTex);

                float2 rotUV = o.uv.xy;
                rotUV -= 0.5;

                float s = sin(_Rotation * 2 * UNITY_PI / 10);
                float c = cos(_Rotation * 2 * UNITY_PI / 10);

                float2x2 rotMatrix = float2x2(c,-s,
                                              s,c);

                rotUV = mul(rotMatrix, rotUV);
                rotUV += 0.5;

                o.rotUV = rotUV;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 finalColor = fixed4(1,1,1,1);

                fixed4 frontTex = tex2D(_FrontTex, i.uv.xy);
                fixed4 backTex = tex2D(_BackTex, i.uv.zw);

                float2 newUV =  i.rotUV * 2 - 1;

                float radial = atan2(newUV.y, newUV.x)/(UNITY_PI);
                radial = 1-(radial * 0.5 + 0.5);

                float reveal = smoothstep(radial - (_Smoothness * _Reveal), radial + (_Smoothness * ( 1 - _Reveal)), _Reveal);

                //finalColor.rgb = reveal.xxx;
                finalColor = lerp(frontTex, backTex, reveal);


                return finalColor;
            }
            ENDCG
        }
    }
}
