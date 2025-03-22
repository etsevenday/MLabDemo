// https://lilithgames.feishu.cn/wiki/wikcnNhSw0Pic7MjVIOo0xFfrKh
// Ver 2.2.1 增加适配RectMask2D
Shader "UEP/Universal/Sequence"
{
    Properties
    {
        [PerRendererData] _MainTex("_MainTex(主贴图)", 2D) = "white" {}
		_HorAmount("_HorAmount(序列图横向数量,一行几个)", int) = 4
		_MaxAmount("_MaxAmount(序列图总数量,一共多少个)", int) = 16
		[Space]
		_FrameRate("_FrameRate(循环:播放速度(帧率),0则不循环)", float) = 30
		_Frame("_Frame(不循环:K帧0-1,当前帧数)", Range(0,1)) = 0
		[Space]
		_Intensity ("_Intensity(颜色强度,默认值1)", float) = 1

		[Header(Setting)]
		[Space]
        [KeywordEnum(AlphaBlend,Additive,AddEx)] _Blend("_Blend(叠加模式)", int) = 0
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("_SrcBlend", int) = 5
        [HideInInspector][Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("_DstBlend", int) = 10
        [Toggle]_ZWrite("_ZWrite(深度写入)", int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("_ZTest(深度检测)", int) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("_Cull(剔除)", int) = 2
		[Header(Clip)]
		[Space]
		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("_UseUIAlphaClip", int) = 0
		_AlphaClipThreshold("_AlphaClipThreshold", Float) = 0.001

		[HideInInspector]_StencilComp("Stencil Comparison", int) = 8
		[HideInInspector]_Stencil("Stencil ID", int) = 0
		[HideInInspector]_StencilOp("Stencil Operation", int) = 0
		[HideInInspector]_StencilWriteMask("Stencil Write Mask", int) = 255
		[HideInInspector]_StencilReadMask("Stencil Read Mask", int) = 255

		//[HideInInspector]_GammaRadio("Gamma Radio", Float) = 1
    }
    SubShader
    {
        Tags 
		{ 
			"RenderType"="Transparent"
			"Queue"="Transparent"
			"IgnoreProjector"="True"
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

		Blend[_SrcBlend][_DstBlend]
		Cull[_Cull]
		ZTest[_ZTest]
		ZWrite[_ZWrite]

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

			#pragma multi_compile __ UNITY_UI_CLIP_RECT
            #pragma multi_compile __ UNITY_UI_ALPHACLIP

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"
			//#include "Common/ColorCommon.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                fixed4 vertexColor : COLOR;

            };

            struct v2f
            {
                float4 param : TEXCOORD0;		//xy:uv zw:worldPosition
                float4 vertex : SV_POSITION;
                fixed4 vertexColor : COLOR;

            };

            sampler2D _MainTex;
			fixed4 _ClipRect;
            CBUFFER_START(UnityPerMaterial)
				float _HorAmount, _MaxAmount;
				float _FrameRate, _Frame;

				fixed _AlphaClipThreshold;

				fixed _Intensity;
            CBUFFER_END
			//half _GammaRadio;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.vertexColor = v.vertexColor;
				o.param.zw = v.vertex.xy;

				// 计算序列帧UV
				// 循环时根据帧率; 不循环根据k帧:下标0到(n-1)
				fixed time = floor(_Time.y*_FrameRate+_Frame*(_MaxAmount-1));
				fixed row = floor(time/_HorAmount);
				fixed column = time - row * _HorAmount;
				int _VerAmount = floor((_MaxAmount-1)/_HorAmount);
				o.param.xy = v.uv + half2(column , _VerAmount - row);
				// 实现序列图集中只显示其中一张
				o.param.x /= _HorAmount;
				o.param.y /= _VerAmount+1;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				fixed4 col = 1;

				#ifdef UNITY_UI_CLIP_RECT
					col.a *= UnityGet2DClipping(i.param.zw, _ClipRect);
					if(col.a < 0.001)
					{
						return 0;
					}
				#endif

				#ifdef UNITY_UI_ALPHACLIP
					if(col.a < _AlphaClipThreshold)
						return 0;
				#endif

				fixed4 vertexColor = i.vertexColor;
                col = tex2D(_MainTex, i.param.xy)*vertexColor;
				col.rgb *= _Intensity;
				//col.rgb = CommonColorConvert(col.rgb);
				//col.a = CommonAlphaConvert(col.a, _GammaRadio);
				return col;
            }
            ENDCG
        }
    }
	CustomEditor "ShaderEditorUniversal"
}
