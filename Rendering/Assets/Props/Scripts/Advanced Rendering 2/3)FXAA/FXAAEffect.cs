using UnityEngine;
using System;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class FXAAEffect : MonoBehaviour
{
    [Range(0f, 1f)]
    public float subpixelBlending = 1f;

    [Range(0.0312f, 0.0833f)]
    public float contrastThreshold = 0.0312f;

    [Range(0.063f, 0.333f)]
    public float relativeThreshold = 0.063f;

    [HideInInspector]
    public Shader fxaaShader;

    [NonSerialized]
    Material fxaaMaterial;

    public enum LuminanceMode { Alpha, Green, Calculate }
    public LuminanceMode luminanceSource;

    public enum shaderPass { luminancePass = 0, fxaaPass }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (fxaaMaterial == null)
        {
            fxaaMaterial = new Material(fxaaShader);
            fxaaMaterial.hideFlags = HideFlags.HideAndDontSave;
        }

        fxaaMaterial.SetFloat("_ContrastThreshold", contrastThreshold);
        fxaaMaterial.SetFloat("_RelativeThreshold", relativeThreshold);
        fxaaMaterial.SetFloat("_SubpixelBlending", subpixelBlending);


        if (luminanceSource == LuminanceMode.Calculate) 
        {
            fxaaMaterial.DisableKeyword("LUMINANCE_GREEN");
            RenderTexture luminanceTex = RenderTexture.GetTemporary
                (source.width, source.height, 0, source.format);
            Graphics.Blit(source, luminanceTex, fxaaMaterial, (int)shaderPass.luminancePass);
            Graphics.Blit(luminanceTex, destination, fxaaMaterial, (int)shaderPass.fxaaPass);
            RenderTexture.ReleaseTemporary(luminanceTex);
        }
        else
        {
            if (luminanceSource == LuminanceMode.Green)
            {
                fxaaMaterial.EnableKeyword("LUMINANCE_GREEN");
            }
            else
            {
                fxaaMaterial.DisableKeyword("LUMINANCE_GREEN");
            }
            Graphics.Blit(source, destination, fxaaMaterial, (int)shaderPass.fxaaPass);
        }
    }
}