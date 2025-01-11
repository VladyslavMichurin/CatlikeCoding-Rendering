Shader "ShadersMadeByVlad/4)BlendStatesShader"
{
    Properties
    {
        [MainTexture] _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", color) = (1,1,1,1)

        // 5 and 10, because those are defaults for alpha blend
        [Enum(UnityEngine.Rendering.BlendMode)]
        _SrcFactor ("Src Factor", Float) = 5

        [Enum(UnityEngine.Rendering.BlendMode)]
        _DstFactor ("Dst Factor", Float) = 10

        [Enum(UnityEngine.Rendering.BlendOp)]
        _Opp ("Operation", Float) = 0
    }
    SubShader
    {
        Tags 
        { 
        "RenderType" = "Opaque"
        }
        LOD 100
        Blend [_SrcFactor] [_DstFactor]
        BlendOp [_Opp]

        // blend formula
        // source = whatever this shader outputs
        // destination = whatever is in the Background

        // source * fsource + destination * fdestination

        // Alpha Blend
        // source * fsource + destination * fdestination
        // White * 0.75 + BackgroundColor * (1-0.75)
        // We see 75% white and 25% bg

        // Additive
        // source * fsource + destination * fdestination
        // source * 1 + destination * 1
        // Grass + BG

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

            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uvs = i.uv;
                fixed4 finalColor = tex2D(_MainTex, uvs);



                return finalColor;
            }
            ENDCG
        }
    }
}
