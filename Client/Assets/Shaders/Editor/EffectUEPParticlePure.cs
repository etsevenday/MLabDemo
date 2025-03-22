using UnityEngine;
using UnityEditor;
using System.IO;
using System.Linq;

public class EffectUEPParticlePure : ShaderGUI
{
    public override void OnGUI(MaterialEditor _editor, MaterialProperty[] _properties)
    {
        Material targetMat = _editor.target as Material;
        _editor.SetDefaultGUIWidths();
        HelpDocument(_editor);

        var _Blend = ShaderGUI.FindProperty("_Blend", _properties);

        DoParam("_NoiseTex", new GUIContent("_NoiseTex(扰动图)"), _editor, _properties);
        DoParam("_NoiseIntensity", new GUIContent("_NoiseIntensity(扰动强度)"), _editor, _properties);
        DoParam("_MaskTex", new GUIContent("_MaskTex(遮罩图，R：整体遮罩，G：第二层遮罩，B：第三层遮罩)"), _editor, _properties);
        DoParam("_MainColor", new GUIContent("_MainColor(整体颜色)"), _editor, _properties);

        DoParam("_MainTex", new GUIContent("_FirstTex(粒子贴图，会读取RawImage的参数)"), _editor, _properties);
        DoParam("_FirstParticle", new GUIContent("_FirstParticle(第一层参数，x:X轴速度  y:Y轴速度  z:旋转值  w:亮度 )"), _editor, _properties);

        //DoParam("_SecondToggle", new GUIContent("_SecondToggle(开启第二层效果)"), _editor, _properties);
        DoParam("_SecondTex", new GUIContent("_SecondTex(第二层 贴图)"), _editor, _properties);
        if (targetMat.GetTexture("_SecondTex"))
        {
            targetMat.EnableKeyword("UEP_VARIANT_1");
            DoParam("_SecondParticle", new GUIContent("_SecondParticle(第二层参数，x:X轴速度  y:Y轴速度  z:旋转值  w:亮度 )"), _editor, _properties);
            DoParam("_ThirdTex", new GUIContent("_ThirdTex(第三层 贴图)"), _editor, _properties);
            if (targetMat.GetTexture("_ThirdTex"))
            {
                targetMat.EnableKeyword("UEP_VARIANT_2");
                DoParam("_ThirdParticle", new GUIContent("_ThirdParticle(第三层参数，x:X轴速度  y:Y轴速度  z:旋转值  w:亮度 )"), _editor, _properties);
            }
            else
            {
                targetMat.DisableKeyword("UEP_VARIANT_2");
            }
        }
        else
        {
            targetMat.DisableKeyword("UEP_VARIANT_1");
            targetMat.DisableKeyword("UEP_VARIANT_2");
            targetMat.SetInt("_ThirdToggle", 0);
        }

        _editor.ShaderProperty(_Blend, new GUIContent("_Blend(叠加模式)", "叠加方式，AlphaBlend普通模式，Additive线性减淡，AddEx叠得更亮"));
        switch (targetMat.GetInt("_Blend"))
        {

            case 0:
                targetMat.SetFloat("_SrcBlend", 5);
                targetMat.SetFloat("_DstBlend", 10);
                targetMat.SetFloat("_BlendOp", 0);
                break;
            case 1:
                targetMat.SetFloat("_SrcBlend", 5);
                targetMat.SetFloat("_DstBlend", 1);
                targetMat.SetFloat("_BlendOp", 0);
                break;
            case 2:
                targetMat.SetFloat("_SrcBlend", 1);
                targetMat.SetFloat("_DstBlend", 1);
                targetMat.SetFloat("_BlendOp", 0);
                break;
            default:
                Debug.LogError("Missing parameter: _Blend");
                break;
        }
        DoParam("_ZWrite", new GUIContent("_ZWrite(深度写入)", "深度写入,默认关闭"), _editor, _properties);
        DoParam("_ZTest", new GUIContent("_ZTest(深度检测)", "深度检测,默认Disabled"), _editor, _properties);
        DoParam("_Cull", new GUIContent("_Cull(剔除)", "剔除,默认剔除背面"), _editor, _properties);
        _editor.RenderQueueField();
    }
    private void DoParam(string _string, GUIContent _guiContent, MaterialEditor _Editor, MaterialProperty[] _property)
    {
        GUILayout.BeginHorizontal();
        var m_param = ShaderGUI.FindProperty(_string, _property);
        _Editor.ShaderProperty(m_param, _guiContent);
        GUILayout.EndHorizontal();
    }
    public void HelpDocument(MaterialEditor _Editor)
    {
        GUI.skin.button.wordWrap = true;
        Color preBackground = GUI.backgroundColor;
        Color preContent = GUI.contentColor;
        GUI.backgroundColor = Color.gray;
        GUI.contentColor = Color.white;
        if (GUILayout.Button("打开帮助文档"))
        {
            var material = _Editor.target as Material;
            var shader = material.shader;
            string assetPath = AssetDatabase.GetAssetPath(shader);
            string line = File.ReadLines(assetPath).First();
            line = line.TrimStart('/', ' ');
            Help.BrowseURL(line);
        }
        GUI.skin.button.wordWrap = false;
        GUI.backgroundColor = preBackground;
        GUI.contentColor = preContent;
    }
}
