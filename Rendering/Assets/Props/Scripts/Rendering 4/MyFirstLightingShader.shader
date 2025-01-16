Shader "_MyShaders/_CatlikeCoding/04)MyFirstLightingShader"
{
    Properties
    {
		_Tint ("Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Albedo", 2D) = "white" {}
        [Gamma] _Metallic ("Metallic", Range(0, 1)) = 0
        _Smoothness ("Smoothness", Range(0, 1)) = 0.1
    }
    SubShader
    {

        Pass
        {
            Tags
            {
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM

            #pragma target 3.0

            #pragma vertex vert
            #pragma fragment frag

            // no need to include "UnityCG.cginc", because "UnityStandardBRDF.cginc" aldeay has it
            //#include "UnityCG.cginc"

            //#include "UnityStandardBRDF.cginc"
            //#include "UnityStandardUtils.cginc"

            //it includes all above libraries
            #include "UnityPBSLighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD2;
            };

            float4 _Tint;

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _Metallic;
            float _Smoothness;

            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // same as bot (no transpose)
                //0.normal = mul((float3x3)unity_ObjectToWorld, v.normal);

                //same as below
                //o.normal = mul(transpose(unity_ObjectToWorld), float4(v.normal, 0));

                o.normal = UnityObjectToWorldNormal(v.normal);
                //o.normal = normalize(o.normal);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                i.normal = normalize(i.normal);

                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

                float3 lightColor = _LightColor0.rgb;
                float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;
                
                float3 specularTint;
                float oneMinusReflectivity;
                albedo = DiffuseAndSpecularFromMetallic(albedo, _Metallic, specularTint, oneMinusReflectivity);

                // float3 diffuse = albedo * lightColor * DotClamped(lightDir, i.normal);

                //float3 reflectionDir = reflect(-lightDir, i.normal);
                //float3 halfVector = normalize(lightDir + viewDir);

                // float3 specular = specularTint * lightColor * pow(
				//	DotClamped(halfVector, i.normal),
				//	_Smoothness * 100
				//);

                //return float4(diffuse + specular, 1);

                UnityLight light;
                light.color = lightColor;
                light.dir = lightDir;
                light.ndotl = DotClamped(i.normal, lightDir);

                UnityIndirect indirectLight;
				indirectLight.diffuse = 0;
				indirectLight.specular = 0;

                return UNITY_BRDF_PBS(
					albedo, specularTint,
					oneMinusReflectivity, _Smoothness,
					i.normal, viewDir,
                    light, indirectLight
				);
            }
            ENDCG
        }
    }
}
