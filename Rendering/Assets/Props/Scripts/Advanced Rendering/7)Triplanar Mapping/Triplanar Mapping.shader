Shader "_MyShaders/_CatlikeCoding/Advanced Rendering/7)Triplanar Mapping"
{
   Properties {
		[NoScaleOffset] _MainTex ("Albedo", 2D) = "white" {}
		[NoScaleOffset] _MOHSMap ("MOHS", 2D) = "white" {}
		[NoScaleOffset] _NormalMap ("Normals", 2D) = "white" {}

		_MapScale ("Map Scale", Float) = 1
		_BlendOffset ("Blend Offset", Range(0, 0.5)) = 0.25
		_BlendExponent ("Blend Exponent", Range(1, 8)) = 2
		_BlendHeightStrength ("Blend Height Strength", Range(0, 0.99)) = 0.5
	}

	SubShader {

		Pass 
		{
			Tags 
			{
				"LightMode" = "ForwardBase"
			}

			CGPROGRAM

			#pragma target 3.0

			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			#pragma multi_compile_instancing

			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			#define FORWARD_BASE_PASS

			#include "MyTriplanarMapping.cginc"
			#include "My Lighting.cginc"

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

			#pragma target 3.0

			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog

			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			#include "MyTriplanarMapping.cginc"
			#include "My Lighting.cginc"

			ENDCG
		}
		Pass 
		{
			Tags 
			{
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM

			#pragma target 3.0

			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing

			#pragma vertex MyShadowVertexProgram
			#pragma fragment MyShadowFragmentProgram

			#include "My Shadows.cginc"

			ENDCG
		}
	}
}