#if !defined(FLAT_WIREFRAME_INCLUDED)
#define FLAT_WIREFRAME_INCLUDED

#include "My Lighting.cginc"

[maxvertexcount(3)]
void MyGeometryProgram(triangle InterpolatorsVertex i[3], inout TriangleStream<InterpolatorsVertex> stream) 
{
    float3 p0 = i[0].worldPos.xyz;
	float3 p1 = i[1].worldPos.xyz;
	float3 p2 = i[2].worldPos.xyz;

    float3 triangleNormal = normalize(cross(p1 - p0, p2 - p0));
    i[0].normal = triangleNormal;
	i[1].normal = triangleNormal;
	i[2].normal = triangleNormal;

    stream.Append(i[0]);
    stream.Append(i[1]);
    stream.Append(i[2]);
}


#endif