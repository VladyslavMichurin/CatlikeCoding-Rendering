using UnityEngine;
using UnityEditor;
using Codice.Client.BaseCommands;

public class MyCatlikeCodingShaderGUI : ShaderGUI
{
    Material target;
    MaterialEditor editor;
    MaterialProperty[] properties;

    enum SmoothnessSource
    {
        Uniform, Albedo, Metallic
    }

    public override void OnGUI(MaterialEditor _materialEditor, MaterialProperty[] _properties)
    {
        this.target = _materialEditor.target as Material;
        this.editor = _materialEditor;
        this.properties = _properties;

        DoMain();
        DoSecondary();
    }

    void DoMain()
    {
        GUILayout.Label("Main Maps", EditorStyles.boldLabel);

        MaterialProperty mainTex = FindProperty("_MainTex");
        GUIContent albedoLabel = MakeLabel(mainTex, "Albedo (RGB)");
        MaterialProperty tint = FindProperty("_Tint");

        editor.TexturePropertySingleLine(albedoLabel, mainTex, tint);

        DoMetallic();
        DoSmoothness();
        DoNormals();
        DoOcclusion();
        DoEmission();
        DoDetailMask();

        editor.TextureScaleOffsetProperty(mainTex);

    }
    void DoNormals()
    {
        MaterialProperty normalMap = FindProperty("_NormalMap");
        GUIContent normalLabel = MakeLabel(normalMap);
        MaterialProperty bumpScale = FindProperty("_BumpScale");

        Texture tex = normalMap.textureValue;

        EditorGUI.BeginChangeCheck();

        editor.TexturePropertySingleLine(normalLabel, normalMap, normalMap.textureValue ? bumpScale : null);

        if (EditorGUI.EndChangeCheck() && tex != normalMap.textureValue)
        {
            SetKeyword("_NORMAL_MAP", normalMap.textureValue);
        }
    }
    void DoMetallic()
    {
        MaterialProperty metalicMap = FindProperty("_MetallicMap");
        MaterialProperty metalicSlider = FindProperty("_Metallic");
        GUIContent metalicLabel = MakeLabel(metalicMap, "Metallic (R)");

        Texture tex = metalicMap.textureValue;

        EditorGUI.BeginChangeCheck();

        editor.TexturePropertySingleLine(metalicLabel, metalicMap, metalicMap.textureValue ? null : metalicSlider);

        if (EditorGUI.EndChangeCheck() && tex != metalicMap.textureValue)
        {
            SetKeyword("_METALLIC_MAP", metalicMap.textureValue);
        }
    }
    void DoSmoothness()
    {
        SmoothnessSource source = SmoothnessSource.Uniform;

        if (IsKeywordEnabled("_SMOOTHNESS_ALBEDO"))
        {
            source = SmoothnessSource.Albedo;
        }
        else if (IsKeywordEnabled("_SMOOTHNESS_METALLIC"))
        {
            source = SmoothnessSource.Metallic;
        }

        MaterialProperty smoothnessSlider = FindProperty("_Smoothness");
        GUIContent smoothnessLabel = MakeLabel(smoothnessSlider);

        EditorGUI.indentLevel += 2;
        editor.ShaderProperty(smoothnessSlider, smoothnessLabel);
        EditorGUI.indentLevel += 1;
        EditorGUI.BeginChangeCheck();
        source = (SmoothnessSource)EditorGUILayout.EnumPopup(("Source"), source);
        if (EditorGUI.EndChangeCheck())
        {
            RecordAction("Smoothness Source");
            SetKeyword("_SMOOTHNESS_ALBEDO", source == SmoothnessSource.Albedo);
            SetKeyword("_SMOOTHNESS_METALLIC", source == SmoothnessSource.Metallic);
        }
        EditorGUI.indentLevel -= 3;
    }
    void DoOcclusion()
    {
        MaterialProperty occlusionMap = FindProperty("_OcclusionMap");
        MaterialProperty occlusionSlider = FindProperty("_OcclusionStrenght");
        GUIContent occlusionLabel = MakeLabel(occlusionMap, "Occlusion (G)");

        Texture tex = occlusionMap.textureValue;

        EditorGUI.BeginChangeCheck();

        editor.TexturePropertySingleLine(occlusionLabel, occlusionMap, occlusionMap.textureValue ? occlusionSlider : null);

        if (EditorGUI.EndChangeCheck() && tex != occlusionMap.textureValue)
        {
            SetKeyword("_OCCLUSION_MAP", occlusionMap.textureValue);
        }
    }
    void DoEmission()
    {
        MaterialProperty emissionMap = FindProperty("_EmissionMap");
        MaterialProperty emissionColor = FindProperty("_Emission");
        GUIContent emissionLabel = MakeLabel("Emission (RGB)");

        Texture tex = emissionMap.textureValue;

        EditorGUI.BeginChangeCheck();

        editor.TexturePropertyWithHDRColor(emissionLabel, emissionMap, emissionColor, false);

        if (EditorGUI.EndChangeCheck() && tex != emissionMap.textureValue)
        {
            SetKeyword("_EMISSION_MAP", emissionMap.textureValue);

        }
    }
    void DoDetailMask()
    {
        MaterialProperty detailMaskMap = FindProperty("_DetailMask");
        GUIContent detailMaskLabel = MakeLabel(detailMaskMap, "Detail Mask (A)");

        EditorGUI.BeginChangeCheck();

        editor.TexturePropertySingleLine(detailMaskLabel, detailMaskMap);

        if (EditorGUI.EndChangeCheck())
        {
            SetKeyword("_DETAIL_MASK", detailMaskMap.textureValue);
        }
    }

    void DoSecondary()
    {
        GUILayout.Label("Secondary Maps", EditorStyles.boldLabel);

        MaterialProperty detailTex = FindProperty("_DetailTex");
        GUIContent detailLabel = MakeLabel(detailTex, "Albedo (RGB) multiplied by 2");

        EditorGUI.BeginChangeCheck();

        editor.TexturePropertySingleLine(detailLabel, detailTex);

        if (EditorGUI.EndChangeCheck())
        {
            SetKeyword("_DETAIL_ALBEDO_MAP", detailTex.textureValue);
        }

        DoSecondaryNormals();

        editor.TextureScaleOffsetProperty(detailTex);

    }
    void DoSecondaryNormals()
    {
        MaterialProperty detailNormalMap = FindProperty("_DetailNormalMap");
        GUIContent detailNormalLabel = MakeLabel(detailNormalMap);

        Texture tex = detailNormalMap.textureValue;

        EditorGUI.BeginChangeCheck();

        editor.TexturePropertySingleLine(detailNormalLabel, detailNormalMap,
            detailNormalMap.textureValue ? FindProperty("_DetailBumpScale") : null);

        if (EditorGUI.EndChangeCheck() && tex != detailNormalMap.textureValue)
        {
            SetKeyword("_DETAIL_NORMAL_MAP", detailNormalMap.textureValue);
        }
    }

    #region Convinience

    MaterialProperty FindProperty(string _name)
    {
        return FindProperty(_name, properties);
    }

    static GUIContent staticLable = new GUIContent();
    static GUIContent MakeLabel(MaterialProperty _property, string _tooltip = null)
    {
        staticLable.text = _property.displayName;
        staticLable.tooltip = _tooltip;
        return staticLable;
    }
    static GUIContent MakeLabel(string _property, string _tooltip = null)
    {
        staticLable.text = _property;
        staticLable.tooltip = _tooltip;
        return staticLable;
    }

    void SetKeyword(string _keyword, bool _state)
    {
        if (_state)
        {
            foreach(Material m in editor.targets)
            {
                m.EnableKeyword(_keyword);
            }
        }
        else
        {
            foreach (Material m in editor.targets)
            {
                m.DisableKeyword(_keyword);
            }
        }
    }

    bool IsKeywordEnabled(string _keyword)
    {
        return target.IsKeywordEnabled(_keyword);
    }

    void RecordAction(string _lable)
    {
        editor.RegisterPropertyChangeUndo(_lable);
    }
    #endregion

}
