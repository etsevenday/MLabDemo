// Ver. 4.4 重新适配开始位置,结束位置
using UnityEngine;
using UnityEditor;
using System.Linq;
using System.IO;

public class EffectUEPDissolve : ShaderGUI
{
    private const string _HELP_MSG = "1.点击左侧按钮可复制变量名\n2.鼠标停留参数可显示更多信息";
    private const bool _COPY_BTN = true;

    GUILayoutOption[] guiLayoutOptions = { GUILayout.Height(13), GUILayout.Width(13) };     // 按钮button大小
    TextEditor textEditor = new TextEditor();       // 复制内容存放

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        Material material = materialEditor.target as Material;

        materialEditor.SetDefaultGUIWidths();
        HelpDocument(materialEditor);
        EditorGUILayout.HelpBox(_HELP_MSG, MessageType.Info);

        var _Blend = ShaderGUI.FindProperty("_Blend", properties);
        var _Cull = ShaderGUI.FindProperty("_Cull", properties);
        var _ZWrite = ShaderGUI.FindProperty("_ZWrite", properties);
        var _ZTest = ShaderGUI.FindProperty("_ZTest", properties);

        var _StencilComp = ShaderGUI.FindProperty("_StencilComp", properties);
        var _Stencil = ShaderGUI.FindProperty("_Stencil", properties);
        var _StencilOp = ShaderGUI.FindProperty("_StencilOp", properties);

        InitAndParamCopy("_ChangeAmount", new GUIContent("_ChangeAmount(溶解进度)", "溶解进度"), materialEditor, properties);
        InitAndParamCopy("_StartPos", new GUIContent("_StartPos(开始位置)", "开始位置"), materialEditor, properties);
        InitAndParamCopy("_EndPos", new GUIContent("_EndPos(结束位置)", "结束位置"), materialEditor, properties);
        InitAndParamCopy("_MainTex", new GUIContent("_MainTex(溶解消失贴图) _MainTex_ST(TilingAndOffset)", "溶解消失贴图"), materialEditor, properties);
        
        //if (material.GetTexture("_MainTex"))
        {
            InitAndParamCopy("_MainColor", new GUIContent("_MainColor(溶解消失贴图颜色)", "主颜色"), materialEditor, properties);
            InitAndParamCopy("_MainColorPow", new GUIContent("_MainColorPow(溶解消失贴图颜色对比度)", "对比度"), materialEditor, properties);
            InitAndParamCopy("_WaveTex", new GUIContent("_WaveTex(MainTex扰动图) _WaveTex_ST(TilingAndOffset)", "MainTex扰动图"), materialEditor, properties);
            if (material.GetTexture("_WaveTex"))
            {
                material.EnableKeyword("UEP_VARIANT_5");
                InitAndParamCopy("_WavePow", new GUIContent("_WavePow(扰动强度)", "扰动强度"), materialEditor, properties);
                InitAndParamCopy("_WaveMove", new GUIContent("_WaveMove(位移校正)", "位移校正,默认值0.5"), materialEditor, properties);
                InitAndParamCopy("_WaveOffsetSpeed_X", new GUIContent("_WaveOffsetSpeed_X(扰动平移速度X)", "扰动平移速度X"), materialEditor, properties);
                InitAndParamCopy("_WaveOffsetSpeed_Y", new GUIContent("_WaveOffsetSpeed_Y(扰动平移速度Y)", "扰动平移速度Y"), materialEditor, properties);
                InitAndParamCopy("_WaveRotateSpeed", new GUIContent("_WaveRotateSpeed(扰动旋转速度)", "扰动旋转速度"), materialEditor, properties);
            }
            else
            {
                //material.SetFloat("_WavePow", 0);
                material.DisableKeyword("UEP_VARIANT_5");

                //UnityEngine.Rendering.
            }

            InitAndParamCopy("_Gradient", new GUIContent("_Gradient(溶解噪声图) _Gradient_ST(TilingAndOffset)", "溶解噪声图"), materialEditor, properties);
            InitAndParamCopy("_EdgeColor", new GUIContent("_EdgeColor(边缘颜色RGBA)", "边缘颜色RGBA"), materialEditor, properties);
            InitAndParamCopy("_Softness", new GUIContent("_Softness(边缘宽度)", "边缘宽度"), materialEditor, properties);
            if (material.GetTexture("_Gradient"))
            {
                 
                InitAndParamCopy("_DisturbanceGradient", new GUIContent("_DisturbanceGradient(是否扰乱溶解噪声图)", "是否扰乱溶解噪声图"), materialEditor, properties);
                if (material.GetFloat("_DisturbanceGradient") == 1)
                {
                    InitAndParamCopy("_DisturbanceGradientIntensity", new GUIContent("_DisturbanceGradientIntensity(扰乱溶解噪声图强度)", "扰乱溶解噪声图强度"), materialEditor, properties);
                    InitAndParamCopy("_DisturbanceGradientSpd", new GUIContent("_DisturbanceGradientSpd(扰乱溶解噪声图速度)", "扰乱溶解噪声图速度"), materialEditor, properties);
                }
            }

            //检测有无溶解方向图
            InitAndParamCopy("_Angle", new GUIContent("_Angle(溶解方向旋转)", "溶解方向旋转"), materialEditor, properties);
            InitAndParamCopy("_DirectionWithoutTexture", new GUIContent("_DirectionWithoutTexture(无贴图时可开启方向开关)", "无贴图方向开关"), materialEditor, properties);
            InitAndParamCopy("_DissolveWidth", new GUIContent("_DissolveWidth(方向影响程度)", "溶解宽度，受方向direction影响程度,值为1时溶解图不起作用"), materialEditor, properties);
            if (material.GetFloat("_DirectionWithoutTexture") == 0)
            {
                InitAndParamCopy("_DissolveDirection", new GUIContent("_DissolveDirection(溶解方向图) _DissolveDirection_ST(TilingAndOffset)", "溶解方向图"), materialEditor, properties);
                if (material.GetTexture("_DissolveDirection"))
                {
                    material.EnableKeyword("UEP_VARIANT_2");
                    InitAndParamCopy("_DissolveScale", new GUIContent("_DissolveScale(溶解方向图缩放值)", "溶解方向图缩放值，默认值1"), materialEditor, properties);
                }
                else
                {
                    material.DisableKeyword("UEP_VARIANT_2");
                }
            }
            else 
            {
                material.DisableKeyword("UEP_VARIANT_2");
            }

            //检测有无溶解出现图
            InitAndParamCopy("_ChangeTex", new GUIContent("_ChangeTex(溶解出现贴图)", "溶解出现贴图"), materialEditor, properties);
            if (material.GetTexture("_ChangeTex"))
            {
                material.EnableKeyword("UEP_VARIANT_1");
                InitAndParamCopy("_ChangeColor", new GUIContent("_ChangeColor(溶解出现图颜色)", "溶解出现图颜色"), materialEditor, properties);
                InitAndParamCopy("_ChangeColorPow", new GUIContent("_ChangeColorPow(溶解出现图颜色对比度)", "溶解出现图颜色对比度"), materialEditor, properties);
            }
            else
            {
                material.DisableKeyword("UEP_VARIANT_1");
            }
        }

        materialEditor.ShaderProperty(_Blend, new GUIContent("BlendMode叠加模式", "叠加方式，AlphaBlend普通模式，Additive线性减淡，AddEx叠得更亮"));
        switch (material.GetInt("_Blend"))
        {
            case 0:
                material.SetFloat("_SrcBlend", 5);
                material.SetFloat("_DstBlend", 10);
                material.SetFloat("_BlendOp", 0);
                break;

            case 1:
                material.SetFloat("_SrcBlend", 5);
                material.SetFloat("_DstBlend", 1);
                material.SetFloat("_BlendOp", 0);
                break;
            case 2:
                material.SetFloat("_SrcBlend", 1);
                material.SetFloat("_DstBlend", 1);
                material.SetFloat("_BlendOp", 0);
                break;
            //case 2:
            //    material.SetFloat("_SrcBlend", 4);        //SoftAdditive柔和相加
            //    material.SetFloat("_DstBlend", 1);
            //    material.SetFloat("_BlendOp", 0);
            //    break;
            //case 3:
            //    material.SetFloat("_SrcBlend", 1);        //AddEx不受背景叠亮
            //    material.SetFloat("_DstBlend", 10);
            //    material.SetFloat("_BlendOp", 0);
            //    break;
        default:
                Debug.LogError("Missing parameter: _Blend");
                break;
                //case 2:
                //    material.SetFloat("_SrcBlend", 5);
                //    material.SetFloat("_DstBlend", 1);
                //    material.SetFloat("_BlendOp", 2);
                //    break;
                //case 3:
                //    material.SetFloat("_SrcBlend", 4);
                //    material.SetFloat("_DstBlend", 1);
                //    material.SetFloat("_BlendOp", 0);
                //    break;
                //case 4:
                //    material.SetFloat("_SrcBlend", 2);
                //    material.SetFloat("_DstBlend", 0);
                //    material.SetFloat("_BlendOp", 0);
                //    break;
                //case 5:
                //    material.SetFloat("_SrcBlend", 2);
                //    material.SetFloat("_DstBlend", 3);
                //    material.SetFloat("_BlendOp", 0);
                //    break;
                //case 6:
                //    material.SetFloat("_SrcBlend", 2);
                //    material.SetFloat("_DstBlend", 10);
                //    material.SetFloat("_BlendOp", 0);
                //    break;
        }
        materialEditor.ShaderProperty(_ZWrite, new GUIContent("ZWrite深度写入", "深度写入,默认关闭"));
        materialEditor.ShaderProperty(_ZTest, new GUIContent("ZTest深度检测", "深度检测,默认Disabled"));
        materialEditor.ShaderProperty(_Cull, new GUIContent("Cull剔除", "剔除,默认剔除背面"));
        materialEditor.ShaderProperty(_StencilComp, new GUIContent("Stencil Comparison", "比较运算值"));
        materialEditor.ShaderProperty(_Stencil, new GUIContent("Stencil ID", "参考"));
        materialEditor.ShaderProperty(_StencilOp, new GUIContent("Stencil Operation", "模板操作值"));
        materialEditor.RenderQueueField();

//#if UNITY_5_6_OR_NEWER
//        materialEditor.EnableInstancingField();
//        Material m_material = (Material)materialEditor.target;
//        m_material.enableInstancing = true;
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
