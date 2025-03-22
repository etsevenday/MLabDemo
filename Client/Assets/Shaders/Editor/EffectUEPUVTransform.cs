// Ver. 4.2.1 适配动态StencilMask_AlphaClip
using UnityEngine;
using UnityEditor;
using System.Linq;
using System.IO;

public class EffectUEPUVTransform : ShaderGUI
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

        var _Blend = ShaderGUI.FindProperty("_Blend", properties);
        var _Cull = ShaderGUI.FindProperty("_Cull", properties);
        var _ZWrite = ShaderGUI.FindProperty("_ZWrite", properties);
        var _ZTest = ShaderGUI.FindProperty("_ZTest", properties);
        var _StencilComp = ShaderGUI.FindProperty("_StencilComp", properties);
        var _Stencil = ShaderGUI.FindProperty("_Stencil", properties);
        var _StencilOp = ShaderGUI.FindProperty("_StencilOp", properties);
        var _UseUIAlphaClip = ShaderGUI.FindProperty("_UseUIAlphaClip", properties);
        var _AlphaClipThreshold = ShaderGUI.FindProperty("_AlphaClipThreshold", properties);

        InitAndParamCopy("_Color", new GUIContent("_Color(颜色)", "染色颜色,透明度A生效"), m, properties);

        //if(targetMat.IsKeywordEnabled("POLAR"))
        //{
        //          targetMat.DisableKeyword("POLAR");
        //          targetMat.EnableKeyword("UEP_VARIANT_3");
        //          targetMat.EnableKeyword("UEP_VARIANT_4");
        //      }
        InitAndParamCopy("_TwistStrength", new GUIContent("_TwistStrength(扭曲强度)", "扭曲强度,配合BendStrength使用"), m, properties);
        InitAndParamCopy("_BendStrength", new GUIContent("_BendStrength(弯曲强度)", "弯曲强度,配合TwistStrength使用"), m, properties);
        InitAndParamCopy("_M_Rot_Center_X", new GUIContent("_M_Rot_Center_X(旋转中心X)", "旋转中心坐标X"), m, properties);
        InitAndParamCopy("_M_Rot_Center_Y", new GUIContent("_M_Rot_Center_Y(旋转中心Y)", "旋转中心坐标Y"), m, properties);
        InitAndParamCopy("_MainPolar", new GUIContent("_MainPolar(主图极坐标开关)", "开启主图极坐标变换"), m, properties);

        InitAndParamCopy("_MainTex", new GUIContent("_MainTex(主贴图) _MainTex_ST(TilingAndOffset)"), m, properties);
        //if (targetMat.GetTexture("_MainTex"))
        {
            InitAndParamCopy("_RasAlpha", new GUIContent("_RasAlpha(通道R作为透明度A(去黑底))", "主贴图R通道颜色作为透明度（去黑底）"), m, properties);
            InitAndParamCopy("_M_Offset_Xspeed", new GUIContent("_M_Offset_Xspeed(偏移速度X)", "主贴图偏移速度X"), m, properties);
            InitAndParamCopy("_M_Offset_Yspeed", new GUIContent("_M_Offset_Yspeed(偏移速度Y)", "主贴图偏移速度Y"), m, properties);
            InitAndParamCopy("_MainTexRot", new GUIContent("_MainTexRot(旋转角度)", "主贴图旋转角度"), m, properties);
            InitAndParamCopy("_MainTexRotSpeed", new GUIContent("_MainTexRotSpeed(旋转速度)", "主贴图旋转速度"), m, properties);
        }

        InitAndParamCopy("_WarpTex", new GUIContent("_WarpTex(扭曲贴图) _WarpTex_ST(TilingAndOffset)"), m, properties);
        if (targetMat.GetTexture("_WarpTex"))
        {
            targetMat.EnableKeyword("UEP_VARIANT_1");
            InitAndParamCopy("_WarpPolar", new GUIContent("_WarpPolar(扰动图极坐标开关)", "开启扰动图极坐标变换"), m, properties);
            InitAndParamCopy("_Warp_Intensity", new GUIContent("_Warp_Intensity(扭曲强度)", "扭曲强度"), m, properties);
            InitAndParamCopy("_WarpMove", new GUIContent("_WarpMove(扭曲偏移位置校正)", "默认值0.5"), m, properties);
            InitAndParamCopy("_WarpRot", new GUIContent("_WarpRot(旋转角度)", "扭曲贴图旋转角度"), m, properties);
            InitAndParamCopy("_WarpRotSpeed", new GUIContent("_WarpRotSpeed(旋转速度)", "扭曲贴图旋转速度"), m, properties);
            InitAndParamCopy("_Warp_Offset_Xspeed", new GUIContent("_Warp_Offset_Xspeed(偏移速度X)", "扭曲贴图偏移速度X"), m, properties);
            InitAndParamCopy("_Warp_Offset_Yspeed", new GUIContent("_Warp_Offset_Yspeed(偏移速度Y)", "扭曲贴图偏移速度Y"), m, properties);
            InitAndParamCopy("_DiffDirection", new GUIContent("_DiffDirection(双向开关)", "与UEP_VARIANT_4,二选一"), m, properties);
            if (targetMat.GetInt("_DiffDirection") == 1)
            {
                InitAndParamCopy("_DirectionEnum", new GUIContent("_DirectionEnum(X轴，Y轴)", "X轴，Y轴"), m, properties);
                InitAndParamCopy("_DiffSmoothMin", new GUIContent("_DiffSmoothMin(双向过渡最小值)", "双向过渡最小值"), m, properties);
                InitAndParamCopy("_DiffSmoothMax", new GUIContent("_DiffSmoothMax(双向过渡最大值)", "双向过渡最大值"), m, properties);
            }
        }
        else
        {
            targetMat.DisableKeyword("UEP_VARIANT_1");
        }

        InitAndParamCopy("_MaskTex", new GUIContent("_MaskTex(轮廓遮罩贴图) _MaskTex_ST(TilingAndOffset)"), m, properties);
        if (targetMat.GetTexture("_MaskTex"))
        {
            targetMat.EnableKeyword("UEP_VARIANT_2");
            InitAndParamCopy("_MaskMode", new GUIContent("_MaskMode(遮罩模式)", "Alpha:透明遮罩 Wrap:扰乱强度遮罩"), m, properties);
            InitAndParamCopy("_Mask_Offset_Xspeed", new GUIContent("_Mask_Offset_Xspeed(偏移速度X)", "轮廓遮罩贴图偏移速度X"), m, properties);
            InitAndParamCopy("_Mask_Offset_Yspeed", new GUIContent("_Mask_Offset_Yspeed(偏移速度Y)", "轮廓遮罩贴图偏移速度Y"), m, properties);
            InitAndParamCopy("_MaskRot", new GUIContent("_MaskRot(旋转角度)", "轮廓遮罩贴图旋转角度"), m, properties);
            InitAndParamCopy("_MaskRotSpeed", new GUIContent("_MaskRotSpeed(旋转速度)", "轮廓遮罩贴图旋转速度"), m, properties);
            InitAndParamCopy("_MaskSmoothstepMin", new GUIContent("_MaskSmoothstepMin(平滑调整Min)", "轮廓遮罩贴图调整Min(默认值0),Min和Max相差越大越平滑"), m, properties);
            InitAndParamCopy("_MaskSmoothstepMax", new GUIContent("_MaskSmoothstepMax(平滑调整Max)", "轮廓遮罩贴图调整Max(默认值0),Min和Max相差越大越平滑"), m, properties);
            InitAndParamCopy("_MaskOnly", new GUIContent("_MaskOnly(只使用透明通道)", "只使用贴图的透明通道(默认值0)"), m, properties);
            InitAndParamCopy("_MaskScale", new GUIContent("_MaskScale(缩放)", "控制遮罩图的缩放值"), m, properties);
        }
        else
        {
            targetMat.DisableKeyword("UEP_VARIANT_2");
        }
        InitAndParamCopy("_ColorTex", new GUIContent("_ColorTex(颜色贴图RGB)", "用于叠加效果的颜色贴图"), m, properties);
        if (targetMat.GetTexture("_ColorTex") != null)
        {
            targetMat.EnableKeyword("UEP_VARIANT_6");
            InitAndParamCopy("_ColorMoveSpdX", new GUIContent("_ColorMoveSpdX(偏移平移速度X轴)", "颜色贴图X轴平移速度"), m, properties);
            InitAndParamCopy("_ColorRot", new GUIContent("_ColorRot(旋转角度)", "颜色贴图旋转角度"), m, properties);
            InitAndParamCopy("_ColorRotSpd", new GUIContent("_ColorRotSpd(旋转速度)", "颜色贴图旋转速度"), m, properties);
        }
        else
        {
            targetMat.DisableKeyword("UEP_VARIANT_6");
        }
        //m.ShaderProperty(_ColorMaskTex, "ColorMaskTex颜色遮罩贴图");
        //if(targetMat.GetTexture("_ColorMaskTex"))
        //{
        //    targetMat.EnableKeyword("_COLORMASK");  
        //    m.ShaderProperty(_ColorMask_Offset_Xspeed, new GUIContent("_ColorMask_Offset_Xspeed(偏移速度X)", "颜色遮罩贴图偏移速度X"));
        //    m.ShaderProperty(_ColorMask_Offset_Yspeed, new GUIContent("_ColorMask_Offset_Yspeed(偏移速度Y)", "颜色遮罩贴图偏移速度Y"));
        //    m.ShaderProperty(_ColorMaskRot, new GUIContent("_ColorMaskRot(旋转角度)", "颜色遮罩贴图旋转角度"));
        //    m.ShaderProperty(_ColorMaskRotSpeed, new GUIContent("_ColorMaskRotSpeed(旋转速度)", "颜色遮罩贴图旋转速度"));
        //}
        //else{
        //    targetMat.DisableKeyword("_COLORMASK");  
        //}



        m.ShaderProperty(_Blend, new GUIContent("_Blend(叠加模式)", "叠加方式，AlphaBlend普通模式，Additive线性减淡，AddEx叠得更亮"));
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
            //case 4:
            //    targetMat.SetFloat("_SrcBlend", 2);
            //    targetMat.SetFloat("_DstBlend", 1);
            //    targetMat.SetFloat("_BlendOp", 0);
            //    break;
            default:
                Debug.LogError("Missing parameter: _Blend");
                break;
        }
        m.ShaderProperty(_ZWrite, new GUIContent("_ZWrite(深度写入)", "深度写入,默认关闭"));
        m.ShaderProperty(_ZTest, new GUIContent("_ZTest(深度检测)", "深度检测,默认Disabled"));
        m.ShaderProperty(_Cull, new GUIContent("_Cull(剔除)", "剔除,默认剔除背面"));
        m.ShaderProperty(_StencilComp, new GUIContent("Stencil Comparison", "比较运算值"));
        m.ShaderProperty(_Stencil, new GUIContent("Stencil ID", "参考"));
        m.ShaderProperty(_StencilOp, new GUIContent("Stencil Operation", "模板操作值"));
        m.ShaderProperty(_UseUIAlphaClip, new GUIContent("_UseUIAlphaClip", "使用AlphaClip"));
        m.ShaderProperty(_AlphaClipThreshold, new GUIContent("_AlphaClipThreshold", "AlphaClip裁切值"));
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
