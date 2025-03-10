// Upgrade NOTE: replaced 'UNITY_PASS_TEXCUBE(unity_SpecCube1)' with 'UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0)'

#if !defined(MY_LIGHTING_INCLUDED)
#define MY_LIGHTING_INCLUDED

#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

struct appdata
{
   float4 vertex : POSITION;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float2 uv : TEXCOORD0;
};

struct Interpolators 
{
	float4 pos : SV_POSITION;
	float4 uv : TEXCOORD0;
	float3 normal : TEXCOORD1;

	#if defined(BINORMAL_PER_FRAGMENT)
		float4 tangent : TEXCOORD2;
	#else
		float3 tangent : TEXCOORD2;
		float3 binormal : TEXCOORD3;
	#endif

	float3 worldPos : TEXCOORD4;

    SHADOW_COORDS(5)

	#if defined(VERTEXLIGHT_ON)
		float3 vertexLightColor : TEXCOORD6;
	#endif
};

    float4 _Tint;

    sampler2D _MainTex, _DetailTex;
    float4 _MainTex_ST, _DetailTex_ST;


    sampler2D _NormalMap, _DetailNormalMap;
    float _BumpScale, _DetailBumpScale;

    float _Metallic;
    float _Smoothness;


void ComputeVertexLightColor (inout Interpolators i) 
{

    #if defined(VERTEXLIGHT_ON)
       
        i.vertexLightColor = Shade4PointLights(
        unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
        unity_LightColor[0].rgb, unity_LightColor[1].rgb,
        unity_LightColor[2].rgb, unity_LightColor[3].rgb,
        unity_4LightAtten0, i.worldPos, i.normal
        );

    #endif

}

float3 CreateBinormal(float3 normal, float3 tangent, float binormalSign)
{
    return cross(normal, tangent.xyz) * (binormalSign * unity_WorldTransformParams.w);
}

Interpolators MyVertexProgram (appdata v)
{
    Interpolators i;

	i.pos = UnityObjectToClipPos(v.vertex);
	i.worldPos = mul(unity_ObjectToWorld, v.vertex);
	i.normal = UnityObjectToWorldNormal(v.normal);

	#if defined(BINORMAL_PER_FRAGMENT)
		i.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
	#else
		i.tangent = UnityObjectToWorldDir(v.tangent.xyz);
		i.binormal = CreateBinormal(i.normal, i.tangent, v.tangent.w);
	#endif
		
	i.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
	i.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);

    TRANSFER_SHADOW(i);

	ComputeVertexLightColor(i);

    return i;
}

UnityLight CreateLight (Interpolators i)
{
    UnityLight light;

    #if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)

    light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);

    #else
    light.dir = _WorldSpaceLightPos0.xyz;

    #endif

	UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);


    light.color = _LightColor0.rgb * attenuation;
    light.ndotl = DotClamped(i.normal, light.dir);

    return light;
}

float3 BoxProjection(float3 direction, float3 position, float4 cubemapPosition, float3 boxMin, float3 boxMax)
{
    //boxMin -= position; 
    //boxMax -= position;

    //float x = (direction.x > 0 ? boxMax.x : boxMin.x) / direction.x; 
    //float y = (direction.y > 0 ? boxMax.y : boxMin.y) / direction.y; 
    //float z = (direction.z > 0 ? boxMax.z : boxMin.z) / direction.z;

    //float scalar = min(min(x, y), z);
    // same as below

    #if UNITY_SPECCUBE_BOX_PROJECTION
    UNITY_BRANCH
        if (cubemapPosition.w > 0) 
        {
		    float3 factors = ((direction > 0 ? boxMax : boxMin) - position) / direction;
		    float scalar = min(min(factors.x, factors.y), factors.z);
		    direction = direction * scalar + (position - cubemapPosition);
	    }
    #endif
	return direction;
}

UnityIndirect CreateIndirectLight (Interpolators i, float3 viewDir) 
{
	UnityIndirect indirectLight;
	indirectLight.diffuse = 0;
	indirectLight.specular = 0;

	#if defined(VERTEXLIGHT_ON)
		indirectLight.diffuse = i.vertexLightColor;
	#endif

    #if defined(FORWARD_BASE_PASS)
		indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));

        float3 reflectionDir = reflect(-viewDir, i.normal);

        //float roughness = 1 - _Smoothness;
        //roughness *= 1.7 - 0.7 * roughness;

        //float4 envSample = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectionDir, roughness * UNITY_SPECCUBE_LOD_STEPS);
        //indirectLight.specular = DecodeHDR(envSample, unity_SpecCube0_HDR);
        //same as below

        Unity_GlossyEnvironmentData envData;

        envData.roughness = 1 - _Smoothness;
        envData.reflUVW = BoxProjection(
			reflectionDir, i.worldPos,
			unity_SpecCube0_ProbePosition,
			unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
		);

        float3 probe0 = Unity_GlossyEnvironment
                            (UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData);

        #if UNITY_SPECCUBE_BLENDING
            float interpolator = unity_SpecCube0_BoxMin.w;
            UNITY_BRANCH
            if(interpolator < 0.99999)
            {
                envData.reflUVW = BoxProjection(
                reflectionDir, i.worldPos,
                unity_SpecCube1_ProbePosition,
                unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax
                );

                float3 probe1 = Unity_GlossyEnvironment
                                (UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0), unity_SpecCube0_HDR, envData);

                indirectLight.specular = lerp(probe1, probe0, interpolator);        
            }
            else
            {
                indirectLight.specular = probe0;
            }

        #else
            indirectLight.specular = probe0;
        #endif

	#endif

	return indirectLight;
}

void InitializeFragmentNormal(inout Interpolators i)
{
    float3 mainNormal =
        UnpackScaleNormal(tex2D(_NormalMap, i.uv.xy), _BumpScale);
    float3 detailNormal =
        UnpackScaleNormal(tex2D(_DetailNormalMap, i.uv.zw), _DetailBumpScale);
    float3 tangentSpaceNormal = BlendNormals(mainNormal, detailNormal);

    #if defined(BINORMAL_PER_FRAGMENT)
        float3 binormal = CreateBinormal(i.normal, i.tangent.xyz, i.tangent.w);
    #else
        float3 binormal = i.binormal;
    #endif

    i.normal = normalize(
        tangentSpaceNormal.x * i.tangent +
        tangentSpaceNormal.y * binormal +
        tangentSpaceNormal.z * i.normal
        );
}

fixed4 MyFragmentProgram (Interpolators i) : SV_Target
{
    InitializeFragmentNormal(i);

    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

    float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;
                
    float3 specularTint;
    float oneMinusReflectivity;
    albedo = DiffuseAndSpecularFromMetallic(albedo, _Metallic, specularTint, oneMinusReflectivity);

    return UNITY_BRDF_PBS(
		albedo, specularTint,
		oneMinusReflectivity, _Smoothness,
		i.normal, viewDir,
		CreateLight(i), CreateIndirectLight(i, viewDir)
	);
}
#endif
