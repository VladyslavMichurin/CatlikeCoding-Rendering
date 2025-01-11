Shader "ShadersMadeByVlad/6)FlowShader"
{
    Properties
    {
       [MainTexture] _MainTex ("Texture", 2D) = "white" {}
        _FlowTex ("Flow Texture", 2D) = "white" {}
        _FlowUVTex ("Flow UV Texture", 2D) = "white" {}

        _FlowDir_Tile ("Flow Dir / Tile", vector) = (0,0,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }


        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _FlowTex;
            sampler2D _FlowUVTex;

            float4 _FlowDir_Tile;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = v.uv;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 texUV = tex2D(_FlowUVTex, i.uv.xy);

                texUV.rg *= _FlowDir_Tile.zw;
                texUV.rg += frac(_Time.y * _FlowDir_Tile.xy);

                //fixed4 texFlow = tex2D(_FlowTex, texUV.rg) * texUV.a;
                //fixed4 texColor = tex2D(_MainTex, i.uv.xy) * (1 - texUV.a * texFlow.a);

                fixed4 texFlow = tex2D(_FlowTex, texUV.rg);
                fixed4 texColor = tex2D(_MainTex, i.uv.xy);

                fixed4 finalColor = lerp(texColor, texFlow, texUV.a * texFlow.a);

                return finalColor;
            }
            ENDCG
        }
    }
}
