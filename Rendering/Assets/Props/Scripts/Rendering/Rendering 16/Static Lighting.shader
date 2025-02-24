Shader "_MyShaders/_CatlikeCoding/16)Static Lighting"
{
    Properties
    {
		_Color ("Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Albedo", 2D) = "white" {}

        [NoScaleOffset] _NormalMap ("Normals", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Float) = 1

		[NoScaleOffset] _MetallicMap ("Metallic", 2D) = "white" {}
        [Gamma] _Metallic ("Metallic", Range(0, 1)) = 0
        _Smoothness ("Smoothness", Range(0, 1)) = 0.1

        _DetailTex ("Detail Albedo", 2D) = "gray" {}
        [NoScaleOffset] _DetailNormalMap ("Detail Normals", 2D) = "bump" {}
		_DetailBumpScale ("Detail Bump Scale", Float) = 1

		[NoScaleOffset] _EmissionMap ("Emission", 2D) = "black" {}
		[HDR]_Emission ("Emission", Color) = (0, 0, 0, 0)

		[NoScaleOffset] _OcclusionMap ("Occlusion", 2D) = "white" {}
		_OcclusionStrenght ("Occlusion Strenght", Range(0, 1)) = 1

		[NoScaleOffset] _DetailMask ("Detail Mask", 2D) = "white" {}

		_Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5

		[HideInInspector] _SrcBlend ("_SrcBlend", Float) = 1
		[HideInInspector] _DstBlend ("_DstBlend", Float) = 0
		[HideInInspector] _ZWrite ("_ZWrite", Float) = 1

    }

	CustomEditor "MyCatlikeCodingShaderGUI2"

    CGINCLUDE

	#pragma target 3.0

	#define BINORMAL_PER_FRAGMENT
    //#define FOG_DISTANCE

	ENDCG

	SubShader {

		Pass 
		{
			Name "Forward Base Pass"

			Tags 
			{
				"LightMode" = "ForwardBase"
			}
			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]

			CGPROGRAM

			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog

			#pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
			#pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
			#pragma shader_feature _NORMAL_MAP
			#pragma shader_feature _OCCLUSION_MAP
			#pragma shader_feature _EMISSION_MAP
			#pragma shader_feature _DETAIL_MASK
			#pragma shader_feature _DETAIL_ALBEDO_MAP
			#pragma shader_feature _DETAIL_NORMAL_MAP

			#define FORWARD_BASE_PASS

			#include "My Lighting.cginc"

			ENDCG
		}

		Pass 
		{
			Name "Forward Additive Pass"

			Tags 
			{
				"LightMode" = "ForwardAdd"
			}

			Blend [_SrcBlend] One
			ZWrite Off

			CGPROGRAM

			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog

			#pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
			#pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
			#pragma shader_feature _NORMAL_MAP
			#pragma shader_feature _DETAIL_MASK
			#pragma shader_feature _DETAIL_ALBEDO_MAP
			#pragma shader_feature _DETAIL_NORMAL_MAP

			#include "My Lighting.cginc"

			ENDCG
		}
		
		Pass
		{
			Name "Deferred Pass"

			Tags
			{
				"LightMode" = "Deferred"
			}

			CGPROGRAM

			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			#pragma exclude_renderers nomrt
			#pragma multi_compile_prepassfinal

			#pragma shader_feature _ _RENDERING_CUTOUT 
			#pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
			#pragma shader_feature _NORMAL_MAP
			#pragma shader_feature _OCCLUSION_MAP
			#pragma shader_feature _EMISSION_MAP
			#pragma shader_feature _DETAIL_ALBEDO_MAP
			#pragma shader_feature _DETAIL_NORMAL_MAP

			#define DEFERRED_PASS

			#include "My Lighting.cginc"

			ENDCG
		}

		Pass
		{
			Name "Shadow Pass"

			Tags
			{
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM

			#pragma multi_compile_shadowcaster

			#pragma vertex MyShadowVertexProgram
			#pragma fragment MyShadowFragmentProgram

			#pragma shader_feature _SEMITRANSPARENT_SHADOWS

			#pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
			#pragma shader_feature _SMOOTHNESS_ALBEDO

			#include "My Shadows.cginc"

			ENDCG
		}

		Pass
		{
			Tags
			{
				"LightMode" = "Meta"
			}

			Cull Off

			CGPROGRAM

			#pragma vertex MyLightmappingVertexProgram
			#pragma fragment MyLightmappingFragmentProgram

			#pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
			#pragma shader_feature _EMISSION_MAP
			#pragma shader_feature _DETAIL_MASK
			#pragma shader_feature _DETAIL_ALBEDO_MAP

			#include "My Lightmapping.cginc"

			ENDCG

		}

	}
}