// https://lilithgames.feishu.cn/wiki/wikcnLCAMf8KTEOm9qVpZZuK5lf?from=from_copylink
// Ver. 5.0 溶解算法更替回原来
Shader "UEP/Universal/Dissolve"
{
	Properties
	{
		[Header(MainModule)]
		[Space]
		//_MainTex("溶解消失图 MainTexture", 2D) = "white" {}
		_MainTex("_MainTex(主贴图)", 2D) = "white" {}
		[Header(ChangeModule)]
		[Space]
		[NoScaleOffset]_ChangeTex("溶解出现图 ChangeTexture", 2D) = "" {}
		[Header(DissolveModule)]
		[Space]
		_Gradient("溶解噪声图 Gradient", 2D) = "" {}
		_WaveOffsetSpeed_X("扰动平移速度 _WaveOffsetSpeed_X",float) = 0 
		_WaveOffsetSpeed_Y("扰动平移速度 _WaveOffsetSpeed_Y",float) = 0
		_WaveRotateSpeed("扰动旋转速度 _WaveRotateSpeed",float ) = 0
		_WavePow("扰动强度 _WavePow",float) = 0
		[Space]
		_WaveTex("MainTex扰动图 WaveTex", 2D) = "" {}
		_WaveMove("位移校正WaveMove",float)=0.5

		_DissolveDirection("溶解方向图 DissolveDirection", 2D) = "" {}
		_DissolveScale("方向图缩放", float) = 1
		//_NoiseScale("噪声缩放 NoiseScale", half) = 1
		_DissolveWidth("溶解宽度 DissolveWidth", Range(0, 1)) = 0.5
		[Header(DirectionModule)]
		[Space]
		_Angle("溶解方向角度 Angle", Range(0 , 6.28)) = 0
		[HDR]_MainColor("主颜色 MainColor", Color) = (1,1,1,1)
		[HDR]_ChangeColor("主颜色 ChangeColor", Color) = (1,1,1,1)
		[HDR]_EdgeColor("边缘颜色 EdgeColor", Color) = (1,1,1,1)
		_Softness("边缘软度 Softness", Range(0, 4)) = 0
		_StartPos("开始位置 StartPos", Range(0 , 1)) = 0
		_EndPos("结束位置 EndPos", Range(0 , 1)) = 1
		_ChangeAmount("手动播放进度 ChangeAmount", Range(0 , 1)) = 0
		_ChangeColorPow("变化图颜色对比度 ChangeColorPow", FLOAT) = 1
		_MainColorPow("主颜色对比度 MainColorPow", FLOAT) = 1
		[Toggle]_DirectionWithoutTexture("开关", int) = 0
		[Toggle(UEP_VARIANT_4)]_DisturbanceGradient("开关", int) = 0
		_DisturbanceGradientIntensity("DisturbanceGradientIntensity", Range(0 , 10)) = 0
		_DisturbanceGradientSpd("DisturbanceGradientSpd", Range(0 , 10)) = 0

		[Header(Setting)]
		[Space]
		[KeywordEnum(AlphaBlend,Additive,AddEx)] _Blend("Blend mode", int) = 0
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("SrcBlend", int) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("DstBlend", int) = 10
		[Enum(UnityEngine.Rendering.BlendOp)] _BlendOp("BlendOp", int) = 0
		[Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull", int) = 2
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", int) = 0
		[Toggle]_ZWrite("ZWrite", Int) = 0
        [Header(Stencil)]
		[Space]
		[Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp("Stencil Comparison", int) = 8
		_Stencil("Stencil ID", int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)]_StencilOp("Stencil Operation", int) = 0
		[HideInInspector]_StencilWriteMask("Stencil Write Mask", int) = 255
		[HideInInspector]_StencilReadMask("Stencil Read Mask", int) = 255

		//[HideInInspector]_GammaRadio("Gamma Radio", Float) = 1
	}
	SubShader
	{
		Tags 
		{ 
			"Queue" = "Transparent"
			"RenderType" = "Transparent"
			"CanUseSpriteAtlas" = "True"
			"PreviewType"="Plane"
			"IgnoreProjector"="true"
		}
		// AlphaToMask Off
		//LOD 100
		Stencil
        {
            Ref[_Stencil]
            Comp[_StencilComp]
            Pass[_StencilOp]
            ReadMask[_StencilReadMask]
            WriteMask[_StencilWriteMask]
        }

		Pass
		{
			Blend[_SrcBlend][_DstBlend]
			BlendOp[_BlendOp]
			Cull[_Cull]
			ZTest[_ZTest]
			ZWrite[_ZWrite]

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma shader_feature_local __ UEP_VARIANT_1	// _HaveChangeTexture 是否有替换贴图
			#pragma shader_feature_local __ UEP_VARIANT_2	// _HaveDissolveDirectionTexture 是否有溶解方向图
			//#pragma shader_feature_local __ UEP_VARIANT_3	// _DirectionWithoutTexture_ON 溶解方向
			#pragma shader_feature_local __ UEP_VARIANT_4	// _DisturbanceGradient_ON 是否扰乱溶解噪声图 
			#pragma shader_feature_local __ UEP_VARIANT_5	// _DisturbanceWarp_ON 是否扰乱主贴图 
            #pragma multi_compile __ UNITY_UI_CLIP_RECT


			#include "UnityCG.cginc"
            #include "UnityUI.cginc"
			//#include "Common/ColorCommon.cginc"

			struct Attributes
			{
				half4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
				fixed4 vertexColor : COLOR;
			};

			struct Varings
			{
				float4 uv0 : TEXCOORD0;	     //xy:uv0    zw:worldPosition
				half4 positionCS : SV_POSITION;
				fixed4 vertexColor : COLOR;
			};


			sampler2D _MainTex;
			sampler2D _Gradient;
			#ifdef UEP_VARIANT_1
				sampler2D _ChangeTex;
			#endif
			#ifdef UEP_VARIANT_2
				sampler2D _DissolveDirection;
			#endif
			#ifdef UEP_VARIANT_5
				sampler2D _WaveTex;
			#endif
			CBUFFER_START(UnityPerMaterial)
				half4 _MainColor;
				half4 _ChangeColor;
				half4 _EdgeColor;
				//half4 _EdgeColor2;

				float _Angle;
				float _DissolveScale;
				float _WaveRotateSpeed;
				float _WaveOffsetSpeed_X;
				float _WaveOffsetSpeed_Y;
				float _WavePow;
				float _WaveMove;
				//half _NoiseScale;
				half _ChangeAmount;
				half _Softness;
				half _DissolveWidth;
				half _ChangeColorPow;
				half _MainColorPow;

				half _StartPos;
				half _EndPos;

				float4 _Gradient_ST;
				float4 _MainTex_ST;
				float4 _DissolveDirection_ST;
				float4 _WaveTex_ST;

				//#ifdef _DisturbanceGradient_ON
				float  _DisturbanceGradientIntensity;
				float  _DisturbanceGradientSpd;
				//#endif
				int _DirectionWithoutTexture;
				//half _GammaRadio;
			CBUFFER_END

			half4 _ClipRect;

			float2 UVRotation(float2 UV, float angle)
			{
				float c = cos(angle);
				float s = sin(angle);
				float2 newUV = mul(half2x2(c, -s, s, c), UV - float2(0.5, 0.5)) + float2(0.5, 0.5);
				return newUV;
			}

			Varings vert(Attributes IN)
			{
				Varings o = (Varings)0;
				o.positionCS = UnityObjectToClipPos(IN.positionOS);
				o.uv0.xy = IN.uv;
				o.uv0.zw = IN.positionOS.xy;
				o.vertexColor = IN.vertexColor;
				return o;
			}

			float4 frag(Varings IN) : SV_Target
			{
				if(_ChangeAmount == 1)		//性能考虑
				{
					return 0;
				}
				// 顶点色透明度为0时，return
				fixed4 vertexColor = IN.vertexColor;
				float dissolveAlpha = 1;
				#ifdef UNITY_UI_CLIP_RECT
                    dissolveAlpha *= UnityGet2DClipping(IN.uv0.zw, _ClipRect);
					if((dissolveAlpha*vertexColor.w*_MainColor.w) < 0.001)
					{
						return 0;
					}
				#else
					if((vertexColor.w*_MainColor.w) < 0.001)
					{
						return 0;
					}
                #endif

				//溶解消失贴图 溶解噪声图采样
				//half2 _mainTexUV = IN.uv0;
				float2 uv_i = IN.uv0.xy;
				float2 _mainTexUV = uv_i * _MainTex_ST.xy + _MainTex_ST.zw;
				//if (_WavePow>=0.001){
				#ifdef UEP_VARIANT_5
					float2 _gradientWaveUV = float2((uv_i.x+_Time.y*_WaveOffsetSpeed_X),(uv_i.y+_Time.y*-_WaveOffsetSpeed_Y));
					_gradientWaveUV = UVRotation(_gradientWaveUV,(_Time.y*_WaveRotateSpeed));
					float4 waveTex = tex2D(_WaveTex,_gradientWaveUV* _WaveTex_ST.xy + _WaveTex_ST.zw);
					_mainTexUV = ((waveTex.r-_WaveMove)*_WavePow)+_mainTexUV ;
				#endif
				//}
				half4 mainTex = tex2D(_MainTex, _mainTexUV) * _MainColor;
				mainTex.rgb = pow(max(mainTex.rgb, 0.001), _MainColorPow);
				if(_ChangeAmount == 0)		//性能考虑
				{
					mainTex *= vertexColor;
					return mainTex;
				}
				half4 changeCol = half4(0, 0, 0, 0);

				//检测有无溶解出现图
				#ifdef UEP_VARIANT_1
					//如果有溶解出现图，对拖进的图片进行采样，return溶解消失、出现两图
					changeCol = tex2D(_ChangeTex, uv_i) * _ChangeColor;
					if((mainTex.a + changeCol.a) < 0.001)
					{
						return 0;
					}
					changeCol.rgb = pow(changeCol.rgb, _ChangeColorPow);
				#else
					//如果无，就不采样，return溶解消失图片
					if(mainTex.a < 0.001)
					{
						return 0;
					}
				#endif

				float2 gradientUV = uv_i * _Gradient_ST.xy + _Gradient_ST.zw;
				float2 gradientUVOffset = 0;
				#ifdef UEP_VARIANT_4
					gradientUVOffset = gradientUV + _Time.y * _DisturbanceGradientSpd;
					gradientUVOffset = tex2D(_Gradient, gradientUVOffset);
					gradientUVOffset = (gradientUVOffset - 0.5) * _DisturbanceGradientIntensity;
				#endif
				half4 gradientCol = tex2D(_Gradient, gradientUV + gradientUVOffset);// * _NoiseScale);

				half dissolveDirectionCol;

				//检测有无溶解方向图
				#ifdef UEP_VARIANT_2
					//如果有，添加UV旋转角度参数，对图片进行采样
					float2 newUV = uv_i * _DissolveDirection_ST.xy + _DissolveDirection_ST.zw;
					newUV = UVRotation(newUV, _Angle);
					dissolveDirectionCol = tex2D(_DissolveDirection, (newUV - 0.5)*_DissolveScale + 0.5).r;
				#else
					dissolveDirectionCol = _DirectionWithoutTexture * UVRotation(uv_i, _Angle).x;
					//#ifdef UEP_VARIANT_3
					//	half2 newUV = UVRotation(uv_i, _Angle);
					//	dissolveDirectionCol = newUV.x;
					//#else
					//	dissolveDirectionCol = 0;
					//#endif
				#endif

				//half dissolveProgress = lerp(_StartPos, _EndPos, _ChangeAmount);
				half dissolveProgress = lerp(_StartPos, _EndPos, _ChangeAmount);
				//half dissolveProgress = gradientCol.x - 1.0 + _ChangeAmount * 2.0;

				//溶解描边
				half dissolveOrgin = lerp(gradientCol.r, dissolveDirectionCol, _DissolveWidth);
				half dissolveMove = dissolveOrgin - (dissolveProgress * 2 - 1);
				if(saturate(dissolveMove) + changeCol.a < 0.01)
				{
					return 0;
				}
				//溶解效果 + 图片切换
				half dissolveEffect = smoothstep(dissolveOrgin/2.0 , dissolveOrgin/2.0+_Softness/5.0+0.0001, dissolveMove);
				#ifdef UEP_VARIANT_1
					half3 changeTex = lerp(changeCol.rgb, mainTex.rgb, dissolveEffect);
				#else
					half3 changeTex = mainTex.rgb * dissolveEffect;
				#endif
				dissolveAlpha *= lerp(changeCol.a, mainTex.a, dissolveEffect);

				half findEdge =(1-abs(dissolveEffect-0.5))*2-1;
				//输出结果
				float3 dissolveTex = _EdgeColor.a * lerp(changeTex, _EdgeColor.rgb, findEdge) + (1-_EdgeColor.a) * changeTex;
				
				//convert
				dissolveTex.rgb *= vertexColor.rgb;
				dissolveAlpha *= vertexColor.a;
				//dissolveTex.rgb = CommonColorConvert(dissolveTex.rgb*vertexColor.rgb);
				//dissolveAlpha = CommonAlphaConvert(dissolveAlpha*vertexColor.a, _GammaRadio);
				return float4(dissolveTex.rgb, dissolveAlpha);
			}
			ENDHLSL
		}
	}
	CustomEditor "EffectUEPDissolve"
}
