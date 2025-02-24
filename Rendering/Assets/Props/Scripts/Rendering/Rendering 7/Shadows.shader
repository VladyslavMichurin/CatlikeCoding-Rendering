Shader "_MyShaders/_CatlikeCoding/07)Shadows"
{
    Properties
    {
		_Tint ("Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Albedo", 2D) = "white" {}

        [NoScaleOffset] _NormalMap ("Normals", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Float) = 1

        [Gamma] _Metallic ("Metallic", Range(0, 1)) = 0
        _Smoothness ("Smoothness", Range(0, 1)) = 0.1

        _DetailTex ("Detail Texture", 2D) = "gray" {}
        [NoScaleOffset] _DetailNormalMap ("Detail Normals", 2D) = "bump" {}
		_DetailBumpScale ("Detail Bump Scale", Float) = 1
    }

    CGINCLUDE

	#pragma target 3.0

	#define BINORMAL_PER_FRAGMENT

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

			#include "My Lighting 3.cginc"

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

			#include "My Lighting 3.cginc"

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

			#include "My Shadows.cginc"

			ENDCG
		}

	}
}