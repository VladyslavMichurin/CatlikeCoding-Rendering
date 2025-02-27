Shader "_MyShaders/_CatlikeCoding/Rendering/09)Complex Materials"
{
    Properties
    {
		_Tint ("Tint", Color) = (1, 1, 1, 1)
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
    }

	CustomEditor "MyCatlikeCodingShaderGUI"

    CGINCLUDE

	#pragma target 3.0

	#define BINORMAL_PER_FRAGMENT

	#pragma shader_feature _METALLIC_MAP
	#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
	#pragma shader_feature _EMISSION_MAP

	ENDCG

	SubShader {

		Pass 
		{
			Tags 
			{
				"LightMode" = "ForwardBase"
			}

			CGPROGRAM

			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			#pragma multi_compile __ SHADOWS_SCREEN
			#pragma multi_compile __ VERTEXLIGHT_ON

			#define FORWARD_BASE_PASS

			#include "My Lighting 5.cginc"

			ENDCG
		}

		Pass 
		{
			Tags 
			{
				"LightMode" = "ForwardAdd"
			}

			Blend One One
			ZWrite Off

			CGPROGRAM

			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			#pragma multi_compile_fwdadd_fullshadows

			#include "My Lighting 5.cginc"

			ENDCG
		}
		
		Pass
		{
			Tags
			{
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM

			#pragma multi_compile_shadowcaster

			#pragma vertex MyShadowVertexProgram
			#pragma fragment MyShadowFragmentProgram

			#include "My Shadows 3.cginc"

			ENDCG
		}

	}
}