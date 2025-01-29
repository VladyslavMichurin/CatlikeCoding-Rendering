using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class DeferredFogEffect : MonoBehaviour
{
    public Shader deferredFog;

    [NonSerialized]
    Material fogMaterial;

    [NonSerialized]
    Camera deferredCamera;

    [NonSerialized]
    Vector3[] frustumCorners;

    [NonSerialized]
    Vector4[] vectorArray;


    [ImageEffectOpaque]
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(fogMaterial == null)
        {
            deferredCamera = GetComponent<Camera>();
            frustumCorners = new Vector3[4];
            vectorArray = new Vector4[4];
            fogMaterial = new Material(deferredFog);
        }

        deferredCamera.CalculateFrustumCorners
            (new Rect(0, 0, 1f, 1f), deferredCamera.farClipPlane, deferredCamera.stereoActiveEye, frustumCorners);

        // CalculateFrustumCorners and quad to render image effects have different corner order
        vectorArray[0] = frustumCorners[0];
        vectorArray[1] = frustumCorners[3];
        vectorArray[2] = frustumCorners[1];
        vectorArray[3] = frustumCorners[2];
        fogMaterial.SetVectorArray("_FrustumCorners", vectorArray);

        Graphics.Blit(source, destination, fogMaterial);
    }
}
