using UnityEngine;

public class TangentSpaceVisualizer : MonoBehaviour
{
    void OnDrawGizmos()
    {
        MeshFilter filter = GetComponent<MeshFilter>();
        if(filter)
        {
            Mesh mesh = filter.sharedMesh;
            if(mesh) 
            {
                ShowTangentSpace(mesh);
            }
        }
    }

    void ShowTangentSpace(Mesh mesh)
    {
        Vector3[] verts = mesh.vertices;
        Vector3[] normals = mesh.normals;
        Vector4[] tangents = mesh.tangents;


        for(int i = 0; i < verts.Length; i++) 
        {
            ShowTangentSpace(
                transform.TransformPoint(verts[i]),
                transform.TransformDirection(normals[i]),
                transform.TransformDirection(tangents[i]),
                tangents[i].w);
        }

    }

    public float offset = 0.01f;
    public float scale = 0.1f;

    void ShowTangentSpace(Vector3 vertex, Vector3 normal, Vector3 tangent, float binormalSign)
    {
        vertex += normal * offset;

        Gizmos.color = Color.green;
        Gizmos.DrawLine(vertex, vertex + normal * scale);

        Gizmos.color = Color.red;
        Gizmos.DrawLine(vertex, vertex + tangent * scale);

        Vector3 binormal = Vector3.Cross(normal, tangent) * binormalSign;
        Gizmos.color = Color.blue;
        Gizmos.DrawLine(vertex, vertex + binormal * scale);
    }
}
