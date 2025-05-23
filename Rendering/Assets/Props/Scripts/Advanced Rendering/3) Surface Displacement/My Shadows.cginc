#if !defined(MY_SHADOWS_INCLUDED)
	#define MY_SHADOWS_INCLUDED

	#include "UnityCG.cginc"

	#if defined(_RENDERING_FADE) || defined(_RENDERING_TRANSPARENT)
		#if defined(_SEMITRANSPARENT_SHADOWS)
			#define SHADOWS_SEMITRANSPARENT 1
		#else
			#define _RENDERING_CUTOUT
		#endif
	#endif

	#if SHADOWS_SEMITRANSPARENT || defined(_RENDERING_CUTOUT)
		#if !defined(_SMOOTHNESS_ALBEDO)
			#define SHADOWS_NEED_UV 1
		#endif
	#endif

	#if defined(_PARALLAX_MAP) && defined(VERTEX_DISPLACEMENT_INSTEAD_OF_PARALLAX)
		#undef _PARALLAX_MAP
		#define VERTEX_DISPLACEMENT 1
		#define _DisplacementMap _ParallaxMap
		#define _DisplacementStrength _ParallaxStrength
		#if !defined(SHADOWS_NEED_UV)
			#define SHADOWS_NEED_UV 1
		#endif
	#endif

	struct appdata 
	{
		UNITY_VERTEX_INPUT_INSTANCE_ID 

		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float2 uv : TEXCOORD0;
	};

	struct InterpolatorsVertex 
	{
		UNITY_VERTEX_INPUT_INSTANCE_ID 

		float4 position : SV_POSITION;

		#if SHADOWS_NEED_UV
			float2 uv : TEXCOORD0;
		#endif

		#if defined(SHADOWS_CUBE)
			float3 lightVec : TEXCOORD1;
		#endif
	};

	struct Interpolators 
	{
		UNITY_VERTEX_INPUT_INSTANCE_ID 

		#if SHADOWS_SEMITRANSPARENT || defined(LOD_FADE_CROSSFADE)
			UNITY_VPOS_TYPE vpos : VPOS;
		#else
			float4 positions : SV_POSITION;
		#endif
	
		#if SHADOWS_NEED_UV
			float2 uv : TEXCOORD0;
		#endif

		#if defined(SHADOWS_CUBE)
			float3 lightVec : TEXCOORD1;
		#endif
	};

	UNITY_INSTANCING_BUFFER_START(InstanceProperties)
		UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
	UNITY_INSTANCING_BUFFER_END(InstanceProperties)

	sampler2D _MainTex;
	float4 _MainTex_ST;
	float _Cutoff;
	sampler3D _DitherMaskLOD;

	sampler2D _ParallaxMap;
	float _ParallaxStrength;

	float GetAlpha(Interpolators i)
	{
		float alpha = UNITY_ACCESS_INSTANCED_PROP(InstanceProperties, _Color).a;

		#if SHADOWS_NEED_UV
        
			alpha *= tex2D(_MainTex, i.uv.xy).a;

		#endif

		return alpha;
	}

	#define MyVertexProgram MyShadowVertexProgram

	InterpolatorsVertex  MyShadowVertexProgram(appdata v)
	{
		InterpolatorsVertex  i;
		UNITY_SETUP_INSTANCE_ID(v);
		UNITY_TRANSFER_INSTANCE_ID(v, i);

		#if SHADOWS_NEED_UV
			i.uv = TRANSFORM_TEX(v.uv, _MainTex);
		#endif

		#if VERTEX_DISPLACEMENT
			float displacement = tex2Dlod(_DisplacementMap, float4(i.uv.xy, 0, 0)).g;
			displacement = (displacement - 0.5) * _DisplacementStrength;
			v.normal = normalize(v.normal);
			v.vertex.xyz += v.normal * displacement;
		#endif

		#if defined(SHADOWS_CUBE)
			i.position = UnityObjectToClipPos(v.vertex);
			i.lightVec = 
				mul(unity_ObjectToWorld, v.vertex).xyz - _LightPositionRange.xyz;
		#else
			i.position = UnityClipSpaceShadowCasterPos(v.vertex.xyz, v.normal);
			i.position = UnityApplyLinearShadowBias(i.position);
		#endif

		return i;
	}

	fixed4 MyShadowFragmentProgram(Interpolators i) : SV_Target
	{
		UNITY_SETUP_INSTANCE_ID(i);

		#if defined(LOD_FADE_CROSSFADE)
			UnityApplyDitherCrossFade(i.vpos);
		#endif

		float alpha = GetAlpha(i);
		#if defined(_RENDERING_CUTOUT)
			clip(alpha - _Cutoff);
		#endif

		#if SHADOWS_SEMITRANSPARENT
			float dither = tex3D(_DitherMaskLOD, float3(i.vpos.xy * 0.25, alpha * 0.9375)).a;
			clip(dither - 0.01);
		#endif

		#if defined(SHADOWS_CUBE)
			float depth = lenght(i.lightVec) + unity_LightShadowBias.x;
			depth *= _LightPositionRange.w;
			return UnityEncodeCubeShadowDepth(depth);
		#else
			return 0;
		#endif

	}

#endif