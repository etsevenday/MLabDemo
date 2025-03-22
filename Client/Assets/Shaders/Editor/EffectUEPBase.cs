using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using UnityEngine.Rendering;

public class EffectUEPBase : ShaderGUI {
    // 合并变量的类
    public class MergedProperty {
        public string propertyName;         // 合并变量的名称
        public string displayName;          // 在Inspector中显示的名称
        public string[] labels;             // 每个分量的显示名称
        public float[] minValues;           // 每个分量的最小值
        public float[] maxValues;           // 每个分量的最大值
    }

    // 合并变量的信息
    protected List<MergedProperty> mergedProperties = new List<MergedProperty>();
    protected virtual void MergedProperties() {
    }


    // 用于缓存MaterialProperty的字典
    private Dictionary<string, MaterialProperty> propertyDict = new Dictionary<string, MaterialProperty>();


    // 将属性存到字典中
    private void FindProperties(MaterialProperty[] props) {
        propertyDict.Clear();
        foreach (var prop in props) {
            propertyDict[prop.name] = prop;
        }
    }

    // 绘制合并属性
    private void DrawMergedProperty(MaterialEditor materialEditor, MaterialProperty prop, MergedProperty mergedProperty) {
        EditorGUILayout.LabelField(mergedProperty.displayName, EditorStyles.boldLabel);
        EditorGUI.indentLevel++;

        Vector4 vector = prop.vectorValue;

        EditorGUI.BeginChangeCheck();
        for (int i = 0; i < mergedProperty.labels.Length; i++) {
            vector[i] = EditorGUILayout.Slider(mergedProperty.labels[i], vector[i], mergedProperty.minValues[i], mergedProperty.maxValues[i]);
        }
        if (EditorGUI.EndChangeCheck()) {
            prop.vectorValue = vector;
        }

        EditorGUI.indentLevel--;
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties) {
        FindProperties(properties);
        EditorGUI.BeginChangeCheck();
        MergedProperties();
        foreach (var prop in properties) {
            materialEditor.SetDefaultGUIWidths();
            var mergedProperty = mergedProperties.Find(mp => mp.propertyName == prop.name);
            if (mergedProperty != null) {
                // 需要合并的属性
                EditorGUIUtility.labelWidth -= 280f;
                DrawMergedProperty(materialEditor, prop, mergedProperty);
            } else {
                if ((prop.flags & MaterialProperty.PropFlags.HideInInspector) == 0) {
                    float propertyHeight = materialEditor.GetPropertyHeight(prop, prop.displayName);
                    Rect controlRect = EditorGUILayout.GetControlRect(true, propertyHeight, EditorStyles.layerMaskField);
                    materialEditor.ShaderProperty(controlRect, prop, prop.displayName);
                }
            }
        }
        EditorGUILayout.Space();
        EditorGUILayout.Space();
        if (SupportedRenderingFeatures.active.editableMaterialRenderQueue) {
            materialEditor.RenderQueueField();
        }

        materialEditor.EnableInstancingField();
        materialEditor.DoubleSidedGIField();
    }
}
