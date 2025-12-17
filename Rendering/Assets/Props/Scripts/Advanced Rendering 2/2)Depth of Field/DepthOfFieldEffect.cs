using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class DepthOfFieldEffect : MonoBehaviour
{
    [Range(0.1f, 100f)]
    public float focusDistance = 10f;

    [Range(0.1f, 10f)]
    public float focusRange = 3f;

    [Range(1f, 10f)]
    public float bokehRadius = 4f;

    enum Passes 
    {
        circleOfConfusionPass = 0,
        preFilterPass,
        bokehPass,
        postFilterPass,
        combinePass
    }

    [HideInInspector]
    public Shader dofShader;

    [NonSerialized]
    Material dofMaterial;

    private void OnRenderImage(RenderTexture _source, RenderTexture _destination)
    {
        if(dofMaterial == null)
        {
            dofMaterial = new Material(dofShader);
            dofMaterial.hideFlags = HideFlags.HideAndDontSave;
        }

        dofMaterial.SetFloat("_BokehRadius", bokehRadius);
        dofMaterial.SetFloat("_FocusDistance", focusDistance);
        dofMaterial.SetFloat("_FocusRange", focusRange);

        RenderTexture coc = RenderTexture.GetTemporary
            (_source.width, _source.height, 0,
            RenderTextureFormat.RHalf, RenderTextureReadWrite.Linear);

        int width = _source.width / 2;
        int height = _source.height / 2;
        RenderTextureFormat format = _source.format;
        RenderTexture dof0 = RenderTexture.GetTemporary(width, height, 0, format);
        RenderTexture dof1 = RenderTexture.GetTemporary(width, height, 0, format);

        dofMaterial.SetTexture("_CoCTex", coc);
        dofMaterial.SetTexture("_DoFTex", dof0);

        Graphics.Blit(_source, coc, dofMaterial, (int)Passes.circleOfConfusionPass);
        Graphics.Blit(_source, dof0, dofMaterial, (int)Passes.preFilterPass);
        Graphics.Blit(dof0, dof1, dofMaterial, (int)Passes.bokehPass);
        Graphics.Blit(dof1, dof0, dofMaterial, (int)Passes.postFilterPass);
        Graphics.Blit(_source, _destination, dofMaterial, (int)Passes.combinePass);

        RenderTexture.ReleaseTemporary(coc);
        RenderTexture.ReleaseTemporary(dof0);
        RenderTexture.ReleaseTemporary(dof1);
    }
}
