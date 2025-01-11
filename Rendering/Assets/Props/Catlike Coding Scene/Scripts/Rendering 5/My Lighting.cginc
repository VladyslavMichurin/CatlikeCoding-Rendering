#if !defined(MY_LIGHTING_INCLUDED)
#define MY_LIGHTING_INCLUDED

#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"

struct appdata
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float2 uv : TEXCOORD0;
};

struct Interpolators
{
    float4 vertex : SV_POSITION;
    float3 normal : TEXCOORD1;
    float2 uv : TEXCOORD0;
    float3 worldPos : TEXCOORD2;

    #if defined(VERTEXLIGHT_ON)

    float3 vertexLightColor : TEXCOORD3;

    #endif

};

float4 _Tint;

sampler2D _MainTex;
float4 _MainTex_ST;

float _Metallic;
float _Smoothness;

void ComputeVertexLightColor (inout Interpolators i) 
{

    #if defined(VERTEXLIGHT_ON)
        
        //float3 lightPos = float3(unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x);

        //float3 lightVec = lightPos - i.worldPos;
        //float3 lightDir = normalize(lightVec);
        //float ndotl = DotClamped(i.normal, lightDir);
        //float attenuation = 1 / (1 + dot(lightVec, lightVec) * unity_4LightAtten0.x);

        //i.vertexLightColor = unity_LightColor[0].rgb * ndotl * attenuation;

        i.vertexLightColor = Shade4PointLights(
        unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
        unity_LightColor[0].rgb, unity_LightColor[1].rgb,
        unity_LightColor[2].rgb, unity_LightColor[3].rgb,
        unity_4LightAtten0, i.worldPos, i.normal
        );

    #endif

}

Interpolators MyVertexProgram (appdata v)
{
    Interpolators o;

    o.vertex = UnityObjectToClipPos(v.vertex);
    o.worldPos = mul(unity_ObjectToWorld, v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);

    // same as bot (no transpose)
    //0.normal = mul((float3x3)unity_ObjectToWorld, v.normal);

    //same as below
    //o.normal = mul(transpose(unity_ObjectToWorld), float4(v.normal, 0));

    o.normal = UnityObjectToWorldNormal(v.normal);

    ComputeVertexLightColor(o);
    //o.normal = normalize(o.normal);

    return o;
}

UnityLight CreateLight (Interpolators i)
{
    UnityLight light;

    #if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)

    light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);

    #else
    light.dir = _WorldSpaceLightPos0.xyz;

    #endif

    //float3 lightVec = _WorldSpaceLightPos0.xyz - i.worldPos;
    //float attenuation = 1 / (1 + dot(lightVec, lightVec));

    UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos);

    light.color = _LightColor0.rgb * attenuation;
    light.ndotl = DotClamped(i.normal, light.dir);

    return light;
}

UnityIndirect CreateIndirectLight (Interpolators i) {
	UnityIndirect indirectLight;
	indirectLight.diffuse = 0;
	indirectLight.specular = 0;

	#if defined(VERTEXLIGHT_ON)
		indirectLight.diffuse = i.vertexLightColor;
	#endif

    #if defined(FORWARD_BASE_PASS)
		indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
	#endif

	return indirectLight;
}

fixed4 MyFragmentProgram (Interpolators i) : SV_Target
{
    i.normal = normalize(i.normal);

    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

    float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;
                
    float3 specularTint;
    float oneMinusReflectivity;
    albedo = DiffuseAndSpecularFromMetallic(albedo, _Metallic, specularTint, oneMinusReflectivity);

    return UNITY_BRDF_PBS(
		albedo, specularTint,
		oneMinusReflectivity, _Smoothness,
		i.normal, viewDir,
		CreateLight(i), CreateIndirectLight(i)
	);
}
#endif
