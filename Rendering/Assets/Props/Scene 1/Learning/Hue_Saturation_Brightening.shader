Shader "ShadersMadeByVlad/8)Hue_Saturation_Brightening"
{
    Properties
    {
        [MainTexture] _MainTex ("Texture", 2D) = "white" {}
        _HueShiftTex ("Hue Shift Texture", 2D) = "white" {}

        _HueShift ("Hue Shift", Range(0, 10)) = 0
        _Saturation ("Saturation", Range(0, 5)) = 0
        _Brightness ("Brightness", Range(-1, 1)) = 0
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

            sampler2D _HueShiftTex;

            float _HueShift;
            float _Saturation;
            float _Brightness;

            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            float3 HueShift(float3 _color, float _hueShift)
            {
                float3x3 RGB_TO_YIQ =
                    float3x3 (0.299, 0.587, 0.114,
                              0.5959, -0.275, -0.3213,
                              0.2115, -0.5227, 0.3112);

                float3x3 YIQ_TO_RGB =
                    float3x3 (1, 0.956, 0.619,
                              1, -0.272, -0.647,
                              1, -1.106, 1.702);

                float3 YIQ = mul(RGB_TO_YIQ, _color);

                float Q = YIQ.z;
                float I = YIQ.y;

                float hue = atan2(Q, I) + _hueShift;

                float chroma = length(float2(I, Q)) * _Saturation;

                float shifted_Y = YIQ.x + _Brightness;
                float shifted_I = chroma * cos(hue);
                float shifted_Q = chroma * sin(hue);

                float3 shiftedYIQ = float3(shifted_Y, shifted_I, shifted_Q);

                float3 newRGB = mul(YIQ_TO_RGB, shiftedYIQ);

                return newRGB;
            }

            fixed4 frag (v2f i) : SV_Target
            {   
                fixed4 finalColor = float4(1,1,1,1);
                fixed4 mainTex = tex2D(_MainTex, i.uv);
                fixed hue = tex2D(_HueShiftTex, i.uv).r;
                
                hue = 0;

                finalColor.rgb = HueShift(mainTex.rgb, _HueShift + hue);

                return finalColor;
            }
            ENDCG
        }
    }
}
