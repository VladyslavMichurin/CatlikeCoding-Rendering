Shader "Unlit/JJK_Cursed_Energy"
{
    Properties
    {
        _Albedo ("Energy Color", Color) = (1, 1, 1, 1)
        _OutlineAlbedo ("Outline Color", Color) = (0, 0, 0, 1)

        _MainTex ("Texture", 2D) = "white" {}
        _MainTexAmmount ("Main Texture Ammount", Range(0.0, 1.0)) = 1

         _GradientNoiseAmmount ("Gradient Noise Ammount", Range(0.0, 1.0)) = 1
         _GradientNoiseMovement ("Gradient Noise Movement", Vector) = (0, 0, 0, 0)

         _VoronoiAmmount("Voronoi Power", Range(0.0, 1.0)) = 1
         _VoronoiPower ("Voronoi Power", Range(0.01, 5.0)) = 1
         _VoronoiMovement ("Voronoi Movement", Vector) = (0, 0, 0, 0)


         _Test ("Test", Range(0.01, 1.0)) = 0
         _Test2 ("Test2", Range(0.01, 1.0)) = 0

    }
    SubShader
    {
        Pass 
        {
           Name "Cursed Energy"

           Blend SrcAlpha OneMinusSrcAlpha
           BlendOp Add

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Assets/Props/Experiments/ShaderGraphNoises.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 noiseUV : TEXCOORD1;

            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _Albedo, _OutlineAlbedo;
            float _MainTexAmmount;

            float _GradientNoiseAmmount;
            float4 _GradientNoiseMovement;

            float _VoronoiAmmount, _VoronoiPower;
            float4 _VoronoiMovement;

            float _Test, _Test2;

            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.noiseUV.xy = o.uv;
                o.noiseUV.xy += (-_Time.yy * _GradientNoiseMovement);

                o.noiseUV.zw = o.uv;
                o.noiseUV.zw += (-_Time.yy * _VoronoiMovement);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 finalColor;

                float4 mainTex = tex2D(_MainTex, i.uv);

                float4 gradientNoise;
                float4 voronoiNoise; 

                ShaderGraph_GradientNoise(i.noiseUV.xy, 15, gradientNoise);
                ShaderGraph_VoronoiNoise(i.noiseUV.zw, 2, 2, voronoiNoise);
                voronoiNoise = pow(voronoiNoise, _VoronoiPower);
                voronoiNoise *= gradientNoise.a;

                float4 noisedTex = tex2D(_MainTex, lerp(i.uv, gradientNoise.aa, _GradientNoiseAmmount));

                noisedTex = noisedTex * lerp(1, voronoiNoise.a, _VoronoiAmmount) + (mainTex * _MainTexAmmount);
                noisedTex = saturate(noisedTex * 2);

                float4 finalTex;

                if(noisedTex.a <= _Test)
                    finalTex = 0;
                else
                    finalTex = 1;

                float4 finalOutline; 

                if(noisedTex.a <= _Test2)
                    finalOutline = 0;
                else
                    finalOutline = 1;         

                finalColor = lerp(finalOutline * _OutlineAlbedo, finalTex * _Albedo, finalTex.a);

                return fixed4(finalColor);
            }
            ENDCG
        }

    }
}
