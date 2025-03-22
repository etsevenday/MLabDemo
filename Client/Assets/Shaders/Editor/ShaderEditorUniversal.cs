// Ver:1.1 HelpDocument\BlendMode private->public
#if UNITY_EDITOR
using UnityEngine;
using UnityEditor;
using System.IO;
using System.Linq;

public class ShaderEditorUniversal : ShaderGUI
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        HelpDocument(materialEditor);
        base.OnGUI(materialEditor, properties);
        BlendMode(materialEditor);
    }

    /// <summary>
    /// 叠加模式设置
    /// </summary>
    /// <param name="_materialEditor"></param>
    public void BlendMode(MaterialEditor _materialEditor)
    {
        Material targetMat = _materialEditor.target as Material;
        switch (targetMat.GetInt("_Blend"))
        {
            case 0:
                targetMat.SetInt("_SrcBlend", 5);
                targetMat.SetInt("_DstBlend", 10);
                break;
            case 1:
                targetMat.SetFloat("_SrcBlend", 5);
                targetMat.SetFloat("_DstBlend", 1);
                break;
            case 2:
                targetMat.SetFloat("_SrcBlend", 1);
                targetMat.SetFloat("_DstBlend", 1);
                break;
            default:
                Debug.LogError("Missing parameter: _Blend");
                break;
        }
    }

    /// <summary>
    /// 打开帮助文档
    /// </summary>
    /// <param name="_materialEditor"></param>
    public void HelpDocument(MaterialEditor _materialEditor)
    {
        GUI.skin.button.wordWrap = true;
        Color preBackground = GUI.backgroundColor;
        Color preContent = GUI.contentColor;
        GUI.backgroundColor = Color.gray;
        GUI.contentColor = Color.white;
        if (GUILayout.Button("打开帮助文档"))
        {
            var material = _materialEditor.target as Material;
            var shader = material.shader;
            string assetPath = AssetDatabase.GetAssetPath(shader);
            if (string.IsNullOrEmpty(assetPath))
            {
                return;
            }

            string line = File.ReadLines(assetPath).First();
            if (!line.StartsWith("//"))
            {
                return;
            }

            line = line.TrimStart('/', ' ');

            Help.BrowseURL(line);
        }
        GUI.skin.button.wordWrap = false;
        GUI.backgroundColor = preBackground;
        GUI.contentColor = preContent;
    }
}
#endif