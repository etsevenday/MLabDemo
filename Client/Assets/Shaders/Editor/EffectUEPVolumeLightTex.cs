// Ver. 2.0 通用版本迭代
using UnityEngine;
using UnityEditor;
using System.Linq;
using System.IO;

public class EffectUEPVolumeLightTex : ShaderGUI
{
    private const string _HELP_MSG = "1.点击左侧按钮可复制变量名\n2.鼠标停留参数可显示更多信息";
    private const bool _COPY_BTN = true;

    GUILayoutOption[] guiLayoutOptions = { GUILayout.Height(13), GUILayout.Width(13) };     // 按钮button大小
    TextEditor textEditor = new TextEditor();       // 复制内容存放

    public override void OnGUI(MaterialEditor m, MaterialProperty[] properties)
    {
        Material targetMat = m.target as Material;

        m.SetDefaultGUIWidths();
        HelpDocument(m);
        EditorGUILayout.HelpBox(_HELP_MSG, MessageType.Info);

        var _PolarMask = ShaderGUI.FindProperty("_PolarMask", properties);
        var _AlphaMask = ShaderGUI.FindProperty("_AlphaMask", properties);

        var _Blend = ShaderGUI.FindProperty("_Blend", properties);
        var _Cull = ShaderGUI.FindProperty("_Cull", properties);
        var _ZWrite = ShaderGUI.FindProperty("_ZWrite", properties);
        var _ZTest = ShaderGUI.FindProperty("_ZTest", properties);

        InitAndParamCopy("_UsePolar", new GUIContent("_UsePolar(使用极坐标遮罩)", "使用极坐标遮罩"), m, properties);

        m.ShaderProperty(_PolarMask, new GUIContent("_PolarMask()", "极坐标遮罩贴图，勾选UsePolar使用，用于控制形状"));
        m.ShaderProperty(_AlphaMask, new GUIContent("_AlphaMask(Alpha遮罩贴图，用于控制明暗)", "遮罩贴图,存放单通道贴图(黑白贴图)"));


        InitAndParamCopy("_LightCenterX", new GUIContent("_LightCenterX(光射出点X坐标)", "光射出点X坐标"), m, properties);
        InitAndParamCopy("_LightCenterY", new GUIContent("_LightCenterY(光射出点Y坐标)", "光射出点Y坐标"), m, properties);
        InitAndParamCopy("_LightRange", new GUIContent("_LightRange(光线覆盖扇形范围的角度)", "光线覆盖扇形范围的角度"), m, properties);
        InitAndParamCopy("_LightRotate", new GUIContent("_LightRotate(光线覆盖扇形的旋转角度)", "光线覆盖扇形的旋转角度"), m, properties);
        InitAndParamCopy("_LightLength", new GUIContent("_LightLength(光线长度)", "光线长度"), m, properties);
        InitAndParamCopy("_SwingSpeed", new GUIContent("_SwingSpeed(光线遮罩叠化速度)", "光线遮罩叠化速度"), m, properties);

        InitAndParamCopy("_PolarMaskRotateSpeed", new GUIContent("_PolarMaskRotateSpeed(光线遮罩的旋转速度)", "光线遮罩的旋转速度"), m, properties);

        
        InitAndParamCopy("_DoubleColor", new GUIContent("_DoubleColor(开启两种颜色混合)", "开启两种颜色混合"), m, properties);
        InitAndParamCopy("_Color1", new GUIContent("_Color1(颜色1)", "颜色1"), m, properties);
        if (targetMat.GetInt("_DoubleColor") != 0)
        {
            InitAndParamCopy("_Color2", new GUIContent("_Color2(颜色2)", "颜色2"), m, properties);
            InitAndParamCopy("_ColorMaskNum", new GUIContent("_ColorMaskNum(颜色数量)", "颜色数量"), m, properties);
            InitAndParamCopy("_ColorMaskOffset", new GUIContent("_ColorMaskOffset(颜色遮罩的偏移值)", "颜色遮罩的初始旋转值"), m, properties);
            InitAndParamCopy("_ColorMaskRotateSpeed", new GUIContent("_ColorMaskRotateSpeed(颜色遮罩的旋转速度)", "颜色遮罩的旋转速度"), m, properties);
        }

        InitAndParamCopy("_ColorIntensity", new GUIContent("_ColorIntensity(RGB颜色的强度)", "RGB颜色的强度"), m, properties);
        InitAndParamCopy("_AlphaMuli", new GUIContent("_AlphaMuli(alpha强度)", "alpha强度"), m, properties);

        m.ShaderProperty(_Blend, new GUIContent("BlendMode叠加模式", "叠加方式，AlphaBlend普通模式，Additive线性减淡，AddEx叠得更亮"));
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
            //case 3:
            //    targetMat.SetFloat("_SrcBlend", 1);
            //    targetMat.SetFloat("_DstBlend", 10);
            //    targetMat.SetFloat("_BlendOp", 0);
            //    break;
            default:
                Debug.LogError("Missing parameter: _Blend");
                break;
        }
        m.ShaderProperty(_ZWrite, new GUIContent("ZWrite深度写入", "深度写入,默认关闭"));
        m.ShaderProperty(_ZTest, new GUIContent("ZTest深度检测", "深度检测,默认Disabled"));
        m.ShaderProperty(_Cull, new GUIContent("Cull剔除", "剔除,默认剔除背面"));
        m.RenderQueueField();

//#if UNITY_5_6_OR_NEWER
//        m.EnableInstancingField();
//        Material material = (Material)m.target;
//        material.enableInstancing = true;
//#endif
    }


    /// <summary>
    /// 初始化+添加复制功能方法
    /// </summary>
    /// <param name="_strParam">变量名</param>
    /// <param name="_guiContent">显示GUI内容</param>
    /// <param name="_materialEditor"></param>
    /// <param name="_properties"></param>
    private void InitAndParamCopy(string _strParam, GUIContent _guiContent, MaterialEditor _materialEditor, MaterialProperty[] _properties)
    {
        GUILayout.BeginHorizontal();
        if (_COPY_BTN)
        {
            if (GUILayout.Button("", guiLayoutOptions))
            {
                textEditor.text = _strParam;
                textEditor.OnFocus();
                textEditor.Copy();
            }
        }
        var m_param = ShaderGUI.FindProperty(_strParam, _properties);
        _materialEditor.ShaderProperty(m_param, _guiContent);
        GUILayout.EndHorizontal();
    }


    /// <summary>
    /// 打开帮助文档
    /// </summary>
    /// <param name="materialEditor"></param>
    public void HelpDocument(MaterialEditor materialEditor)
    {
        GUI.skin.button.wordWrap = true;
        Color preBackground = GUI.backgroundColor;
        Color preContent = GUI.contentColor;
        GUI.backgroundColor = Color.gray;
        GUI.contentColor = Color.white;
        if (GUILayout.Button("打开帮助文档"))
        {
            var material = materialEditor.target as Material;
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
