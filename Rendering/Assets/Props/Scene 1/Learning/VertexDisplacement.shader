Shader "ShadersMadeByVlad/7)VertexDisplacement"
{
    Properties
    {
        [MainTexture] _MainTex ("Texture", 2D) = "white" {}
        _DisplacementTex ("Displacement Texture", 2D) = "white" {}
        _DisplacementStrenght ("Displacement Strenght", Range(0, 1)) = 1
        _MoveDir ("Mode Dir", Vector) = (0,0,0,0)

        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }


        Cull [_CullMode]

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
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _DisplacementTex;
            float4 _DisplacementTex_ST;

            float _DisplacementStrenght;

            float4 _MoveDir;

            v2f vert (appdata v)
            {
                v2f o;

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv += frac(_MainTex_ST * _MoveDir.xy * _Time.yy);                       

                float2 dispacementUV = TRANSFORM_TEX(v.uv, _DisplacementTex);

                float xMod = tex2Dlod(_DisplacementTex, float4(dispacementUV.xy, 0,1));
                xMod =  (xMod * 2 - 1);

                dispacementUV.x = sin(xMod * 10 -  (_Time.y * 2));
                dispacementUV.x = dispacementUV.x * _DisplacementStrenght;

                float3 vert = v.vertex;  
                float3 vertModifier = v.normal * dispacementUV.x;
                

                o.vertex = UnityObjectToClipPos(vert + vertModifier);


                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 texColor = tex2D(_MainTex, i.uv);

                return texColor;
            }
            ENDCG
        }
    }
}
