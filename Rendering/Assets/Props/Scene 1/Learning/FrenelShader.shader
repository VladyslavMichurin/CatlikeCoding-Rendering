Shader "ShadersMadeByVlad/_Group2/5)FresnelShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _Intensity ("Fresnel Intensity", Range(0, 10)) = 0
        _Ramp ("Fresnel Ramp", Range(0, 10)) = 0

        [Toggle] NORMAL_MAP ("Normal Map", float) = 0
        _NormalMap ("Normal Map", 2D) = "white" {}

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
        Tags { "RenderType"="Opaque" }
        LOD 100

        Blend [_SrcFactor] [_DstFactor]
        BlendOp [_Opp]

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile __ NORMAL_MAP_ON
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 viewDir : TEXCOORD2;

                float3 tangent : TEXCOORD3;
                float3 bitangent : TEXCOORD4;
            };

            sampler2D _MainTex, _NormalMap;
            float4 _MainTex_ST;

            float _Intensity, _Ramp;

            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);

                #if NORMAL_MAP_ON
                    o.tangent = UnityObjectToWorldDir(v.tangent);
                    o.bitangent = cross(o.tangent, o.normal);
                #endif

                o.viewDir = normalize(WorldSpaceViewDir(v.vertex));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                 float3 finalNormal = i.normal;
                #if NORMAL_MAP_ON
                    float3 normalMap = UnpackNormal(tex2D(_NormalMap, i.uv));
                    finalNormal = normalMap.r * i.tangent + normalMap.g * i.bitangent + normalMap.b * i.normal;
                #endif

                // dot product is positive when vectors point in same dir | 0 when perpendicular | negative when vectors point in dif dir 
                // here we take compare how similar the normal vector is to camera viewDir
                 float fresnelAmount = 1 - max(0,dot(finalNormal, i.viewDir));

                fresnelAmount = pow(fresnelAmount, _Ramp) * _Intensity;

                return fresnelAmount;
            }
            ENDCG
        }
    }
}
