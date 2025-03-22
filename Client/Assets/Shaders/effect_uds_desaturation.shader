// https://lilithgames.feishu.cn/wiki/wikcnaVY1jZDRxZpJQzGzhHfSCd
// ver 2.1 Keyword调整
Shader "UEP/Universal/Desaturation"
{
	Properties
	{
		[PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}

		_Fraction("_Fraction(去色百分比)", Range(0, 1)) = 0
		_Color("_Color(去色图片底色)",color) = (1,1,1,1)
		[Space(13)]
		[Toggle(UEP_VARIANT_1)]_DissolveMask("_DissolveMask(溶解去色开关)", int) = 0
		_Dissolve("_Dissolve(溶解去色百分比)", Range(0 , 1)) = 1
		[NoScaleOffset]_DissolveTex("_DissolveTex(溶解方向图)", 2D) = "" {}
		[Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp("Stencil Comparison", Float) = 8
		_Stencil("Stencil ID", Float) = 0
		[Enum(UnityEngine.Rendering.StencilOp)]_StencilOp("Stencil Operation", Float) = 0
		[HideInInspector]_StencilWriteMask("Stencil Write Mask", Float) = 255
		[HideInInspector]_StencilReadMask("Stencil Read Mask", Float) = 255

		[HideInInspector]_ColorMask("Color Mask", Float) = 15
		//[HideInInspector]_GammaRadio("Gamma Radio", Float) = 1


		[HideInInspector][Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip("Use Alpha Clip", Float) = 0
		//[HideInInspector][Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 4
	}

	SubShader
	{
		Tags 
		{ 
			"RenderType" = "Transparent"
			"Queue" = "Transparent"
			"CanUseSpriteAtlas" = "True"
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}

		Stencil
		{
			Ref[_Stencil]
			Comp[_StencilComp]
			Pass[_StencilOp]
			ReadMask[_StencilReadMask]
			WriteMask[_StencilWriteMask]
		}

		Cull Off
		Lighting Off
		ZWrite Off
		ZTest[unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha
		ColorMask[_ColorMask]

		Pass
		{
			Name "Default"
			//ZTest[_ZTest]
			//Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//#pragma target 2.0

			#include "UnityCG.cginc"
			#include "UnityUI.cginc"
			//#include "Common/ColorCommon.cginc"

			#pragma multi_compile __ UNITY_UI_CLIP_RECT
			#pragma multi_compile __ UNITY_UI_ALPHACLIP
            #pragma shader_feature_local __ UEP_VARIANT_1					// _DissolveMask 溶解Mask

			//#pragma shader_feature _Mask

			struct appdata_t
			{
				half4 vertex   : POSITION;
				float2 texcoord : TEXCOORD0;
                fixed4 vertexColor : COLOR;
					//UNITY_VERTEX_INPUT_INSTANCE_ID

			};

			struct v2f
			{
				half4 vertex   : SV_POSITION;
				float2 texcoord  : TEXCOORD0;
				float2 worldPosition : TEXCOORD1;
                fixed4 vertexColor : COLOR;
				//UNITY_VERTEX_OUTPUT_STEREO
			};

			sampler2D _MainTex;
			#ifdef UEP_VARIANT_1
				sampler2D _DissolveTex;
			#endif
			half4 _ClipRect;
			CBUFFER_START(UnityPerMaterial)
				half4 _MainTex_ST;
				//half4 _DissolveMask_ST;


				//half _GammaRadio;
				half4 _Color;


				fixed _Fraction,_Dissolve;
			CBUFFER_END

			v2f vert(appdata_t v)
			{
				v2f OUT;
				//UNITY_SETUP_INSTANCE_ID(v);
				//UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
				OUT.worldPosition = v.vertex.xy;
				OUT.vertex = UnityObjectToClipPos(v.vertex);

				OUT.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				OUT.vertexColor = v.vertexColor;


				return OUT;
			}

			float4 frag(v2f IN) : SV_Target
			{
				#ifdef UNITY_UI_CLIP_RECT
					half _clip = UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
					if (_clip < 0.001)
					{
						return 0;
					}
				#endif
				//IN.uv2 = IN.texcoord * _DissolveMask_ST.xy + _DissolveMask_ST.zw;
				float4 color = tex2D(_MainTex, IN.texcoord);

				#ifdef UNITY_UI_ALPHACLIP
					if(color.a < 0.001)
					{
						return 0;
					}
				#endif

				half3 _DesaturationColor = half4(0.3, 0.59, 0.11, 0);
				half3 _ColorDes = (1 - _Fraction) * (dot(_DesaturationColor, color.rgb)) + _Fraction * color.rgb * _Color;

				//color.rgb = clamp(0,lerp((1-_Fraction) * (dot(_DesaturationColor, color.rgb)) + _Fraction * color.rgb ,color.rgb,mask.r *_Dissolve),color.rgb);

				#ifdef UEP_VARIANT_1
					half4 mask = tex2D(_DissolveTex, IN.texcoord);
					//half3 _ColorMask = lerp(_ColorDes,color.rgb,min(1,mask.r *_Dissolve));
					half3 color_mask = lerp(_ColorDes,color.rgb,saturate((mask.r + 1.0 + (_Dissolve * -2.0))));
					//saturate( ( mask.r + 1.0 + ( _Progress * -2.0 ) ) )
					//half3 _ColorMask = clamp(0,lerp(_ColorDes,color.rgb,(1-IN.texcoord.x) * _Dissolve ),color.rgb);
					color.rgb = color_mask;

					//#if defined(SHADER_API_GLES3) || defined(SHADER_API_GLES)	
					//					color.rgb = LinearToGammaSpace(color.rgb);
					//#endif	

					return color*IN.vertexColor;
				#endif

				//color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);

				color.rgb = _ColorDes;

				//#if defined(SHADER_API_GLES3) || defined(SHADER_API_GLES)	
				//	color.rgb = LinearToGammaSpace(color.rgb);
				//#endif	

				return color*IN.vertexColor;

			}
		ENDCG
		}
	}
	CustomEditor "ShaderHelpUniversal"
}
