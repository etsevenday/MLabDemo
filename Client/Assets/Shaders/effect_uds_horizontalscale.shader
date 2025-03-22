// https://lilithgames.feishu.cn/wiki/ZOS0w8tNYi0Ahuk2sdpc9JFxnTb
// ver 1.0.0 by.lijiana 支持合批的图片流动，满足梯形缩放的功能
Shader "UEP/Universal/HorizontalScale"
{
    Properties
    {
		[Header(Main)]
        [Space]
        _MainTex ("_MainTex(主贴图,顶点颜色R可左右翻转)", 2D) = "white" {}
        [HDR]_MainColor ("_MainColor(颜色)", Color) = (1,1,1,1)
        _Speed("_Speed(速度)", Range(0,1)) = 0.1
        _ScaleLeft("_ScaleLeft(左缩放值)", Range(0,8)) = 0.5
        _ScaleRight("_ScaleRight(右缩放值)", Range(0,8)) = 4
        _OffsetLeft("_OffsetLeft(左偏移值)", Range(-1,1)) = 0
        _OffsetRight("_OffsetRight(右偏移值)", Range(-1,1)) = 0
        _MaskTex("_MaskTex(遮罩图)", 2D) = "white" {}

		[Header(Setting)]
        [Space]
		[KeywordEnum(AlphaBlend,Additive,AddEx,OneZero)] _Blend("_Blend(叠加模式)", int) = 0
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("SrcBlend", int) = 5
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("DstBlend", int) = 10
		[Toggle]_ZWrite("ZWrite(深度写入)", int) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest(深度检测)", int) = 0
		[Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull(剔除)", int) = 2

		[Header(Clip)]
        [Space]
        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("_UseUIAlphaClip", Float) = 0
		_AlphaClipThreshold("_AlphaClipThreshold", Float) = 0.001

		[HideInInspector]_ColorMask ("Color Mask", Float) = 15
		
        [Header(Stencil)]
        [Space]
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)]_StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255
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
            Name "UIDefaultEx"
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
            sampler2D _MaskTex;
			//int _Breath;
			CBUFFER_START(UnityPerMaterial)
			    fixed4 _MainColor;
			    float4 _MainTex_ST, _MaskTex_ST;
                float _Speed, _ScaleLeft, _ScaleRight, _OffsetLeft, _OffsetRight;
			    fixed _AlphaClipThreshold;
			CBUFFER_END
			fixed4 _TextureSampleAdd;
			float4 _ClipRect;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                OUT.vertex = UnityObjectToClipPos(v.vertex);
                OUT.texcoord.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                OUT.texcoord.zw = TRANSFORM_TEX(v.texcoord, _MaskTex);
                OUT.color = v.color ;

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

                // Mask
                float mask = tex2D(_MaskTex, IN.texcoord.zw).x;

				// Main 贴图采样
                float2 uv0 = IN.texcoord.xy;
                float y = (uv0.y - 0.5);
                uv0.y += lerp(y*_ScaleLeft, y*_ScaleRight, uv0.x);
                uv0.y += lerp(_OffsetLeft, _OffsetRight, uv0.x);
                uv0.x += _Time.y*_Speed;
                uv0.x = lerp(1 - uv0.x, uv0.x, IN.color.r);
                half4 color = tex2D(_MainTex, uv0);
                color *= mask * _MainColor;

				// 透明裁切
				#ifdef UNITY_UI_ALPHACLIP
                    clip(color.a - _AlphaClipThreshold);
                #endif

                return float4(color.rgb, color.a * IN.color.a);
            }
			ENDCG
        }
    }
	CustomEditor "ShaderEditorUniversal"
}
