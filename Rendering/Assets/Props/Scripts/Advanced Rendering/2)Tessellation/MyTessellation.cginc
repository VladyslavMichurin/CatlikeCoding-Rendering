#if !defined(TESSELLATION_INCLUDED)
#define TESSELLATION_INCLUDED

struct TessellationFactors 
{
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};
struct TessellationControlPoint 
{
	float4 vertex : INTERNALTESSPOS;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float2 uv : TEXCOORD0;
	float2 uv1 : TEXCOORD1;
	float2 uv2 : TEXCOORD2;
};

float _TessellationUniform;

[UNITY_domain("tri")]
[UNITY_outputcontrolpoints(3)]
[UNITY_outputtopology("triangle_cw")]
[UNITY_partitioning("fractional_odd")]
[UNITY_patchconstantfunc("MyPatchConstantFunction")]
TessellationControlPoint MyHullProgram (InputPatch<TessellationControlPoint, 3> patch,
						uint id : SV_OutputControlPointID) 
{
    return patch[id];
}

TessellationFactors MyPatchConstantFunction (InputPatch<TessellationControlPoint, 3> patch) 
{
	TessellationFactors f;

	f.edge[0] = _TessellationUniform;
    f.edge[1] = _TessellationUniform;
    f.edge[2] = _TessellationUniform;
	f.inside = _TessellationUniform;

	return f;
}

[UNITY_domain("tri")]
InterpolatorsVertex MyDomainProgram (TessellationFactors factors, 
					OutputPatch<TessellationControlPoint, 3> patch,
                    float3 barycentricCoordinates : SV_DomainLocation) 
{
    appdata data;

    #define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) data.fieldName = \
		patch[0].fieldName * barycentricCoordinates.x + \
		patch[1].fieldName * barycentricCoordinates.y + \
		patch[2].fieldName * barycentricCoordinates.z;

	MY_DOMAIN_PROGRAM_INTERPOLATE(vertex)
	MY_DOMAIN_PROGRAM_INTERPOLATE(normal)
	MY_DOMAIN_PROGRAM_INTERPOLATE(tangent)
	MY_DOMAIN_PROGRAM_INTERPOLATE(uv)
	MY_DOMAIN_PROGRAM_INTERPOLATE(uv1)
	MY_DOMAIN_PROGRAM_INTERPOLATE(uv2)

	return MyVertexProgram(data);
}

TessellationControlPoint MyTessellationVertexProgram (appdata  v) 
{
	TessellationControlPoint p;

	p.vertex = v.vertex;
	p.normal = v.normal;
	p.tangent = v.tangent;
	p.uv = v.uv;
	p.uv1 = v.uv1;
	p.uv2 = v.uv2;

	return p;
}

#endif