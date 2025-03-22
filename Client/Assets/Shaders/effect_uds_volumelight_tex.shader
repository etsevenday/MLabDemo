// https://lilithgames.feishu.cn/wiki/wikcnkJMqh50Chw9BbOkSjUgCLb
// Ver. 2.1 Keyword调整
Shader "UEP/Universal/VolumeLightTex"
{
    Properties
    {
		[PerRendererData]_MainTex("MainTex", 2D) = "white" {} //用作主蒙版
        [NoScaleOffset]_PolarMask("_PolarMask", 2D) = "white" {} //用作极坐标蒙版
		[NoScaleOffset]_AlphaMask("_AlphaMask", 2D) = "white" {} //用作Alpha蒙版，制作明暗变化效果

		_LightCenterX("_LightCenterX", Range(0, 1)) = 0.5
		_LightCenterY("_LightCenterY", Range(0, 1)) = 0.5
		_LightRange("_LightRange", Range(0, 360)) = 90
		_LightRotate("_LightRotate", Range(-180,180)) = 0
		_LightLength("_LightLength", float) = 1
		_SwingSpeed("_SwingSpeed", float) = 1
		_PolarMaskRotateSpeed("_PolarMaskRotateSpeed", float) = 1
		_ColorMaskNum("_ColorMaskNum", float) = 10
		_ColorMaskOffset("_ColorMaskOffset", float) = 0
		_ColorMaskRotateSpeed("_ColorMaskRotateSpeed", Range(-5, 5)) = 0

		[Header(Color)]
        [Space]
		[Toggle(UEP_VARIANT_1)] _DoubleColor("_DoubleColor", Int) = 0
		[Toggle(UEP_VARIANT_2)] _UsePolar("_UsePolar", Int) = 1
		_Color1("Color1",Color) = (0.73,0.45,1,1)
        _Color2("Color2",Color) = (0,1,0.84,1)  
        _ColorIntensity("ColorIntensity", Range(0, 10)) = 1
		_AlphaMuli("AlphaDeepen", Range(1, 10)) = 1

        [Header(Setting)]
        [Space]
        [KeywordEnum(AlphaBlend,Additive,AddEx)] _Blend("Blend mode", int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("SrcBlend", int) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("DstBlend", int) = 10
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp("BlendOp", int) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull", int) = 2
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", int) = 0
        [Toggle]_ZWrite("ZWrite", Int) = 0

        [HideInInspector]_StencilComp("Stencil Comparison", int) = 8
		[HideInInspector]_Stencil("Stencil ID", int) = 0
		[HideInInspector]_StencilOp("Stencil Operation", int) = 0
		[HideInInspector]_StencilWriteMask("Stencil Write Mask", int) = 255
		[HideInInspector]_StencilReadMask("Stencil Read Mask", int) = 255

		[HideInInspector]_GammaRadio("Gamma Radio", Float) = 1

    }
    SubShader
    {
        Tags 
        { 
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "CanUseSpriteAtlas" = "True"
			"PreviewType"="Plane"
			"IgnoreProjector"="true"
        }
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
            Blend[_SrcBlend][_DstBlend]    //Blend [_SrcBlend] [_DstBlend] //SrcAlpha one��  SrcAlpha OneMinusSrcAlpha
            BlendOp[_BlendOp]
            Cull [_Cull]
            ZTest [_ZTest]             
            ZWrite [_ZWrite]

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //#pragma multi_compile  _ RANDOM
            #pragma multi_compile __ UNITY_UI_CLIP_RECT
			#pragma shader_feature_local __ UEP_VARIANT_1					// _DoubleColor 两种颜色染色
			#pragma shader_feature_local __ UEP_VARIANT_2					// _UsePolar 使用极坐标遮罩

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
                float4 uv0 : TEXCOORD0;	     //xy:uv0    zw:worldPosition
                float4 vertex : SV_POSITION;
                fixed4 vertexColor : COLOR;
            };

            sampler2D _MainTex, _AlphaMask;
			#ifdef UEP_VARIANT_2
				sampler2D _PolarMask;
			#endif
			
			CBUFFER_START(UnityPerMaterial)
				float3 _Color1, _Color2;
				float _PolarMaskRotateSpeed, _SwingSpeed, _ColorMaskRotateSpeed;
				half _LightRange, _LightRotate, _LightLength, _LightCenterX, _LightCenterY, _ColorIntensity, _ColorMaskNum, _ColorMaskOffset, _AlphaMuli;
			CBUFFER_END
            fixed4 _ClipRect;
            
			//half _GammaRadio;

			//int _DstBlend;



			//直角坐标系转极坐标
			float2 Polar(float2 UV)
			{
				float2 uv = UV - float2(_LightCenterX, _LightCenterY);
				float distance = length(uv);
				distance /= _LightLength;
				float angle = atan2(uv.x, uv.y);
				float angle01 = (angle /3.14159 + (_LightRange / 360) + (_LightRotate / 180)) / (_LightRange / 180);
				return float2(angle01, distance);
			}
			

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv0.xy = v.uv;
                o.uv0.zw = v.vertex.xy;
                o.vertexColor = v.vertexColor;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 uv0 = i.uv0;

                float mask = tex2D(_MainTex, uv0).r;
				if(mask < 0.001)
				{
					return 0;
				}

                half4 result = 1;

                #ifdef UNITY_UI_CLIP_RECT
                    result.a *= UnityGet2DClipping(i.uv0.zw, _ClipRect);
					if (result.a < 0.001)
					{
						return 0;
					}
                #endif

				float2 UV = Polar(uv0);

				#if UEP_VARIANT_2
					result = tex2D(_PolarMask, UV);
				#endif

				half4 polarMask1 = tex2D(_AlphaMask, UV + _Time.y * _PolarMaskRotateSpeed * float2(-0.01, 0));
				half polarMask2 = tex2D(_AlphaMask, UV + (10 + _Time.y * _PolarMaskRotateSpeed) * float2(0.02, 0)).r;
				
				half polarMask = lerp(polarMask1.r, polarMask2, 0.5 + 0.2 * sin(_Time.y * _SwingSpeed));
				half3 tint = 1;

				#if UEP_VARIANT_1
					half colorMask = 0.5 + 0.5 * sin(UV.x * _ColorMaskNum + _ColorMaskOffset + _ColorMaskRotateSpeed * _Time.y);
					tint = lerp(_Color1, _Color2, colorMask);
				#else
					tint = _Color1;
				#endif
				
				result.rgb *= tint * _ColorIntensity;
				result.a *= mask * polarMask * _AlphaMuli * i.vertexColor.a;

				//convert
				//if (_DstBlend == 10)
				//{
				//	result.rgb = CommonColorConvert(result.xyz);
				//	result.a = CommonAlphaConvert(result.w, _GammaRadio);
				//}

                return result;
            }
            ENDCG
        }
    }
    CustomEditor "EffectUEPVolumeLightTex"
}
