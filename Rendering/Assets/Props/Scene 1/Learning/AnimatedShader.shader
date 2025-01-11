Shader "ShadersMadeByVlad/2)AnimatedShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AnimateXY("Animate X Y", vector) = (0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

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
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            // Declare all variables
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _AnimateXY;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.uv += frac(_AnimateXY.xy * _MainTex_ST.xy * _Time.yy / 8);


                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 finalColor = tex2D(_MainTex, i.uv);

                return finalColor;
            }
            ENDCG
        }
    }
}
