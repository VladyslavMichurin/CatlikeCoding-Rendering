#if !defined(MY_LIGHTMAPPING_INCLUDED)
#define MY_LIGHTMAPPING_INCLUDED

#include "UnityPBSLighting.cginc"
#include "UnityMetaPass.cginc"

struct appdata
{
    float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
	float2 uv1 : TEXCOORD1;
};
struct Interpolators 
{
	float4 pos : SV_POSITION;
	float4 uv : TEXCOORD0;
};

    float4 _Color;
    sampler2D _MainTex, _DetailTex, _DetailMask;
    float4 _MainTex_ST, _DetailTex_ST;

    sampler2D _MetallicMap;
    float _Metallic;
    float _Smoothness;

    sampler2D _EmissionMap;
    float3 _Emission;

	float GetMetallic (Interpolators i) 
	{
		float toReturn = _Metallic;

		#if defined(_METALLIC_MAP)
			toReturn = tex2D(_MetallicMap, i.uv.xy).r;
		#endif

		return toReturn;
	}
	float GetSmoothness (Interpolators i) 
	{
		float smoothness = 1;

		#if defined(_SMOOTHNESS_ALBEDO)
			smoothness = tex2D(_MainTex, i.uv.xy).a;
		#elif defined(_SMOOTHNESS_METALLIC) && defined(_METALLIC_MAP)
			smoothness = tex2D(_MetallicMap, i.uv.xy).a;
		#endif

		return smoothness * _Smoothness;
	}
	float3 GetEmission (Interpolators i) 
	{
		#if defined(_EMISSION_MAP)
			return tex2D(_EmissionMap, i.uv.xy) * _Emission;
		#else
			return _Emission;
		#endif
	}
	float GetDetailMask(Interpolators i)
	{
		#if defined(_DETAIL_MASK)
			return tex2D(_DetailMask, i.uv.xy).a;
		#else
			return 1;
		#endif
	}
	float3 GetAlbedo (Interpolators i) {
		float3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color.rgb;
		#if defined (_DETAIL_ALBEDO_MAP)
			float3 details = tex2D(_DetailTex, i.uv.zw) * unity_ColorSpaceDouble;
			albedo = lerp(albedo, albedo * details, GetDetailMask(i));
		#endif
		return albedo;
	}

	Interpolators MyLightmappingVertexProgram(appdata v)
	{
		Interpolators i;

		v.vertex.xy = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
		v.vertex.z = v.vertex.z > 0 ? 0.0001 : 0;

		i.pos = UnityObjectToClipPos(v.vertex);

		i.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
		i.uv.zw = TRANSFORM_TEX(v.uv1, _DetailTex);

		return i;
	}

	float4 MyLightmappingFragmentProgram(Interpolators i) : SV_TARGET 
	{
		UnityMetaInput surfaceData;	

		surfaceData.Emission = GetEmission(i);
		float oneMinusReflectivity;
		surfaceData.Albedo = DiffuseAndSpecularFromMetallic
			(GetAlbedo(i), GetMetallic(i), surfaceData.SpecularColor, oneMinusReflectivity);
		float roughness = SmoothnessToRoughness(GetSmoothness(i)) * 0.5;
		surfaceData.Albedo += surfaceData.SpecularColor * roughness;

		return UnityMetaFragment(surfaceData);
	}

#endif
