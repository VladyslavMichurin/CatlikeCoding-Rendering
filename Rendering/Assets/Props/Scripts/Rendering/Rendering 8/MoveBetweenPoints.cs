using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MoveBetweenPoints : MonoBehaviour
{
    public float moveSpeed = 1;
    public List<Transform> movePositions;

    private int currentIndex = 0;
    private Vector3 velocity;

    void FixedUpdate()
    {
        transform.position = Vector3.SmoothDamp(transform.position, movePositions[currentIndex].position, ref velocity, 1 / moveSpeed);

        if ((movePositions[currentIndex].position - transform.position).sqrMagnitude < 0.01f)
        {
            ChangeTarget();
        }

    }

    void ChangeTarget()
    {
        currentIndex++;

        if (currentIndex == movePositions.Count)
        {
            currentIndex = 0;
        }
    }

}
