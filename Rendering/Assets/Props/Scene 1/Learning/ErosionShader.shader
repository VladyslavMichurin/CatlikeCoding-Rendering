Shader "ShadersMadeByVlad/5)ErosionShader"
{
    Properties
    {
        [Toggle(EROSION_TYPE)] _ErosionType("Erosion Type", Float) = 0
        [Toggle(AUTO_ANIMATE)] _AutoAnimate("Auto Animate", Float) = 0
        [ShowProperty(AUTO_ANIMATE)] _RevealValue ("Reveal Value", Range(0,1)) = 1

        [MainTexture] _MainTex ("Texture", 2D) = "white" {}
        _MaskTex ("Mask Texture", 2D) = "white" {}
        _Feather ("Feather", Float) = .1
        _ErodeColor("Erode Color", Color) = (1,1,1,1)

        // for blending
        [Enum(UnityEngine.Rendering.BlendMode)]
        _SrcFactor("Src Factor", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)]
        _DstFactor("Dst Factor", Float) = 10
        [Enum(UnityEngine.Rendering.BlendOp)]
        _BlendOp ("Operation", Float) = 0
    }
    SubShader
    {
        Tags 
        { 
        "RenderType"="Opaque"
        }
        LOD 100
        Blend [_SrcFactor] [_DstFactor]
        BlendOp [_BlendOp]

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile

            #pragma shader_feature EROSION_TYPE
            #pragma shader_feature AUTO_ANIMATE

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 uv : TEXCOORD0;
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _MaskTex;
            float4 _MaskTex_ST;

            float _RevealValue, _Feather;
            float4 _ErodeColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv, _MaskTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                fixed4 texColor = tex2D(_MainTex, i.uv.xy);
                fixed4 mask = tex2D(_MaskTex, i.uv.zw);

                float animTime = sin(_Time.y * 2) * 0.5 + 0.5;

                 #ifdef EROSION_TYPE
                
                    float revealAmmount;

                     #ifdef AUTO_ANIMATE

                        revealAmmount = smoothstep(clamp(mask.r - _Feather, 0, 1), mask.r + _Feather, animTime);

                     #else

                        revealAmmount = smoothstep(clamp(mask.r - _Feather, 0, 1), mask.r + _Feather, _RevealValue);

                     #endif

                    return fixed4(texColor.rgb, texColor.a * revealAmmount);
                
                #else
                 float maxDif = 1 - _Feather;
                    float difMuliplier = 1/maxDif;

                    float revealTop;
                    float revealBottom;
                    float revealDif;

                     #ifdef AUTO_ANIMATE

                        revealTop = step(mask.r, animTime);
                        revealBottom = step(mask.r, (animTime - _Feather) * difMuliplier);

                     #else

                        revealTop = step(mask.r, _RevealValue);
                        revealBottom = step(mask.r, (_RevealValue - _Feather) * difMuliplier);

                     #endif
                     revealDif = revealTop - revealBottom;

                     float3 finalCol = lerp(texColor.rgb, _ErodeColor, revealDif);

                     return fixed4(finalCol.rgb, texColor.a * revealTop);
                #endif

            }
            ENDCG
        }
    }
}
