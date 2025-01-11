Shader "  ParticleErode"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ErodeTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags 
        { 
        "RenderType"="Opaque" 
        }

        Blend SrcAlpha OneMinusSrcAlpha


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
                float2 erodeUV : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _ErodeTex;
            float4 _ErodeTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.z = v.uv.z;

                o.erodeUV = TRANSFORM_TEX(v.uv, _ErodeTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
               
                fixed4 finalOutput;

                fixed4 mainTex = tex2D(_MainTex, i.uv);

                float cutoff = i.uv.z;
                float erode =  tex2D(_ErodeTex, i.erodeUV).r;
                erode = step(erode, cutoff);

                finalOutput = fixed4(mainTex.rgb * (1 - erode), 1 - erode);

                return finalOutput;
            }
            ENDCG
        }
    }
}
