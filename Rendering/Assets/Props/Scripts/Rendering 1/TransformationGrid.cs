using UnityEngine;
using System.Collections.Generic;

public class TransformationGrid : MonoBehaviour
{
    public Transform prefab;

    public int gridResolution = 10;

    Transform[] grid;

    List<Transformation> transformations;
    Matrix4x4 transformation;

    private void Awake()
    {
        grid = new Transform[gridResolution * gridResolution * gridResolution];

        for(int curCell = 0, z = 0; z < gridResolution; z++)
        {
            for (int y = 0; y < gridResolution; y++)
            {
                for (int x = 0; x < gridResolution; x++, curCell++)
                {
                    grid[curCell] = CreateGridPoint(x, y, z);
                }
            }
        }

        transformations = new List<Transformation>();



    }

    private void Update()
    {

        UpdateTransformation();

        for (int curCell = 0, z = 0; z < gridResolution; z++)
        {
            for (int y = 0; y < gridResolution; y++)
            {
                for (int x = 0; x < gridResolution; x++, curCell++)
                {
                    grid[curCell].localPosition = TransformPoint(x, y, z);
                }
            }
        }
    }

    Transform CreateGridPoint(int x, int y, int z)
    {
        Transform point = Instantiate<Transform>(prefab);

        point.localPosition = GetCoordinates(x, y, z);
        point.SetParent(this.transform);
        point.GetComponent<MeshRenderer>().material.color = new Color(
            (float)x / gridResolution,
            (float)y / gridResolution,
            (float)z / gridResolution
        );

        return point;
    }

    Vector3 GetCoordinates(int x, int y, int z)
    {
        return new Vector3( 
            x - (gridResolution - 1) * 0.5f,
            y - (gridResolution - 1) * 0.5f,
            z - (gridResolution - 1) * 0.5f
        );
    }

    Vector3 TransformPoint(int x, int y, int z)
    {
        Vector3 coordinates = GetCoordinates(x, y, z);

        return transformation.MultiplyPoint(coordinates);
    }

    private void UpdateTransformation()
    {
        // this line is the same as code below
        GetComponents<Transformation>(transformations);

        /////////////////////////////////////////////////////////////////////////////////////

        //Transformation[] test = GetComponents<Transformation>();
        //foreach (Transformation t in test)
        //{
        //    if (!transformations.Contains(t))
        //    {
        //        transformations.Add(t);
        //    }
        //}

        /////////////////////////////////////////////////////////////////////////////////////

        if (transformations.Count > 0)
        {
            //transformation = transformations[0].Matrix;
            transformation = Matrix4x4.identity;
            for (int i = 0; i < transformations.Count; i++)
            {
                transformation = transformations[i].Matrix * transformation;
            }
        }

    }

}
