// https://lilithgames.feishu.cn/wiki/wikcnMT2sXJ9WrlPrL9BO4sc7Cg
// Ver 1.0 Init 单色投影功能添加
Shader "UEP/Universal/UIColor"
{
    Properties
    {
        [NonModifiableTextureData]_MainTex ("_MainTex(主贴图)", 2D) = "white" {}
		[Header(Main)]
        [HDR]_MainColor ("_MainColor(颜色)", Color) = (1,1,1,1)

		[Header(Setting)]
		[KeywordEnum(AlphaBlend,Additive,AddEx)] _Blend("_Blend(叠加模式)", int) = 0
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("SrcBlend", int) = 5
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("DstBlend", int) = 10
		[Toggle]_ZWrite("ZWrite(深度写入)", int) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest(深度检测)", int) = 0
		[Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull(剔除)", int) = 2

		[Header(Clip)]
        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("_UseUIAlphaClip", Float) = 0
		_AlphaClipThreshold("_AlphaClipThreshold", Float) = 0.001
		
        [Header(Stencil)]
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)]_StencilOp ("Stencil Operation", Float) = 0
        [HideInInspector]_StencilWriteMask ("Stencil Write Mask", Float) = 255
        [HideInInspector]_StencilReadMask ("Stencil Read Mask", Float) = 255
		[HideInInspector]_ColorMask ("Color Mask", Float) = 15
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull [_Cull]
        Lighting Off
        ZWrite [_ZWrite]
        ZTest [_ZTest]
        Blend [_SrcBlend] [_DstBlend]
        ColorMask [_ColorMask]

        Pass
        {
            Name "UEP_UIColor"
			CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #pragma multi_compile __ UNITY_UI_CLIP_RECT
            #pragma multi_compile __ UNITY_UI_ALPHACLIP

            struct appdata_t
            {
                float4 vertex   : POSITION;
                fixed4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float4 texcoord  : TEXCOORD0;		//xy:uv zw:worldPosition
            };

            sampler2D _MainTex;
			CBUFFER_START(UnityPerMaterial)
			    fixed4 _MainColor ,_BreathParam;
			    float4 _MainTex_ST;
			    fixed _AlphaClipThreshold;
			CBUFFER_END
			fixed4 _TextureSampleAdd;
			float4 _ClipRect;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                OUT.texcoord.zw = v.vertex.xy;
                OUT.vertex = UnityObjectToClipPos(v.vertex);

                OUT.texcoord.xy = TRANSFORM_TEX(v.texcoord, _MainTex);

                OUT.color = v.color * _MainColor;

				return OUT;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
				// 遮罩
				#ifdef UNITY_UI_CLIP_RECT
					fixed out_alpha = UnityGet2DClipping(IN.texcoord.zw, _ClipRect);
					if(out_alpha < 0.001)
					{
						return 0;
					}
                #endif

				// 贴图采样
                half4 color = tex2D(_MainTex, IN.texcoord.xy) + _TextureSampleAdd;
                // 直接返回颜色
                color.rgb = IN.color;
                color.a *= IN.color.a;

				// 透明裁切
				#ifdef UNITY_UI_ALPHACLIP
                    clip(color.a - _AlphaClipThreshold);
                #endif

                return color;
            }
			ENDCG
        }
    }
	CustomEditor "ShaderEditorUniversal"
}
