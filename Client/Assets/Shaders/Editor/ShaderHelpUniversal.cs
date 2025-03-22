// Ver:2.0 通用大版本迭代——通用ShaderGUI.editor=帮助文档
#if UNITY_EDITOR
using UnityEngine;
using UnityEditor;
using System.IO;
using System.Linq;

public class ShaderHelpUniversal : ShaderGUI
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        HelpDocument(materialEditor);
        base.OnGUI(materialEditor, properties);
    }
    
    /// <summary>
    /// 打开帮助文档
    /// </summary>
    /// <param name="_materialEditor"></param>
    private void HelpDocument(MaterialEditor _materialEditor)
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