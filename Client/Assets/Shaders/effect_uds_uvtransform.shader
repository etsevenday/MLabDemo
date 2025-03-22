// https://lilithgames.feishu.cn/wiki/wikcnDJ6wZPVBTYkcuWy8HjKRHb
// Ver. 4.2.2 Keyword调整
Shader "UEP/Universal/UVTransform"
{
    Properties
    {
        [Header(Basic)]
        [Space]
        [HDR] _Color("MainColor",color) = (1,1,1,1)
        //[Toggle(POLAR)] _Polar("PolarCoord", Int) = 0
        [Toggle(UEP_VARIANT_3)] _WarpPolar("_WarpPolar", Int) = 0
        [Toggle(UEP_VARIANT_4)] _MainPolar("MainPolar", Int) = 0
        _TwistStrength("TwistStrength",Float) = 0
        _BendStrength("BendStrength",Float) = 0
        _M_Rot_Center_X("M_Rot_Center_X",Float) = 0.5
        _M_Rot_Center_Y("M_Rot_Center_Y",Float) = 0.5

        [Header(MainModule)]
        [Space]
        _MainTex("_MainTex(主贴图)", 2D) = "white" {}
        [Toggle] _RasAlpha("ColorR as alpha", Int) = 0
        _M_Offset_Xspeed("Main Offset Xspeed",Float) = 0
        _M_Offset_Yspeed("Main Offset Yspeed",Float) = 0
        _MainTexRot("MainTexRotation",Float) = 0
        _MainTexRotSpeed("MainTexRotationSpeed",Float) = 0

        [Header(WarpModule)]
        [Space]
        _WarpTex("Warp Texture",2D) = "white" {}
        _Warp_Intensity("Warp Intensity",Float) = 0
        _WarpMove("Warp Move",float) = 0.5
        _WarpRot("WarpTexRotation",Float) = 0
        _WarpRotSpeed("WarpTexRotationSpeed",Float) = 0
        _Warp_Offset_Xspeed("Warp Offset Xspeed",Float) = 0
        _Warp_Offset_Yspeed("Warp Offset Yspeed",Float) = 0
        [Space]
        [Toggle(UEP_VARIANT_5)] _DiffDirection("Diff Direction",int) = 0
        [KeywordEnum(X,Y)] _DirectionEnum("Direction Enum",int) = 0
        _DiffSmoothMin("Diff Smooth Min",float) = 0.3
        _DiffSmoothMax("Diff Smooth Max",float) = 0.7

        [Header(MaskModule)]
        [Space]
        _MaskTex("Mask Texture",2D) = "white" {}
        [KeywordEnum(Alpha,Wrap)] _MaskMode("MaskMode", Int) = 0
        _Mask_Offset_Xspeed("Mask Offset Xspeed",Float) = 0
        _Mask_Offset_Yspeed("Mask Offset Yspeed",Float) = 0
        _MaskRot("MaskTexRotation",Float) = 0
        _MaskRotSpeed("WarpTexRotationSpeed",Float) = 0
        _MaskSmoothstepMin("MaskSmoothstepMin",Float) = 0
        _MaskSmoothstepMax("MaskSmoothstepMax",Float) = 1
        [Toggle]_MaskOnly("MaskOnly",int) = 0
        _MaskScale("MaskScale",float) = 1

		[Header(ColorModule)]
		[Space]
		_ColorTex("Color Texture(RGB)",2D) = "while" {}
		_ColorMoveSpdX("_ColorMoveSpdX",float) = 0
		_ColorRot("ColorRot",float)= 0
		_ColorRotSpd("_ColorRotSpd",float)= 0

        [Header(Setting)]
        [Space]
        [KeywordEnum(AlphaBlend,Additive,AddEx)] _Blend("Blend mode", int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("SrcBlend", int) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("DstBlend", int) = 10
        //[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendA ("SrcBlendA", int) = 5
        //[Enum(UnityEngine.Rendering.BlendMode)] _DstBlendA ("DstBlendA", int) = 10

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
		[HideInInspector]_ColorMask ("Color Mask", Float) = 15
        [Header(Clip)]
        [Space]
        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("_UseUIAlphaClip", int) = 0
		_AlphaClipThreshold("_AlphaClipThreshold", Float) = 0.001
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

            Blend[_SrcBlend][_DstBlend]/*, [_SrcBlendA] [_DstBlendA]*/   //Blend [_SrcBlend] [_DstBlend] //SrcAlpha one；  SrcAlpha OneMinusSrcAlpha
            BlendOp[_BlendOp]
            Cull[_Cull]
            ZTest[_ZTest]
            ZWrite[_ZWrite]
            ColorMask [_ColorMask]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile __ UNITY_UI_CLIP_RECT
            #pragma shader_feature_local __ UEP_VARIANT_1					// _WARP 扰乱
            #pragma shader_feature_local __ UEP_VARIANT_2					// _MASK 遮罩
            #pragma shader_feature_local __ UEP_VARIANT_3					// WARPPOLAR 扰乱贴图极坐标
            #pragma shader_feature_local __ UEP_VARIANT_4 UEP_VARIANT_5	// MAINPOLAR 主贴图极坐标，DIFFDIRECTION 双向扰乱
			#pragma shader_feature_local __ UEP_VARIANT_6					// COLORTEX 颜色贴图
            #pragma multi_compile __ UNITY_UI_ALPHACLIP

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            struct VertexInput
            {
                fixed4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                fixed4 vertexColor : COLOR;
            };

            struct VertexOutput
            {
                fixed4 clipPos : SV_POSITION;
                float4 uv0 : TEXCOORD0;     //xy:uv0    zw:worldPosition
                fixed4 vertexColor : COLOR;
				#ifdef UEP_VARIANT_6
					float2 uv1 : TEXCOORD1;		//xy:uv0
				#endif
            };

			fixed4 _ClipRect;
			sampler2D _MainTex;		//Main
			#ifdef UEP_VARIANT_2		//Mask贴图
				sampler2D _MaskTex;
			#endif
			#ifdef UEP_VARIANT_1		//Warp
				sampler2D _WarpTex;
			#endif
			#ifdef UEP_VARIANT_6		//ColorTex
				sampler2D _ColorTex;
			#endif
			//#ifdef UEP_VARIANT_2		//Mask贴图
			//#endif
            CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
                float _TwistStrength,_BendStrength,_M_Rot_Center_X,_M_Rot_Center_Y,_M_Offset_Xspeed,_M_Offset_Yspeed,_MainTexRot,_MainTexRotSpeed;
				fixed4 _Color;
				int _RasAlpha;
			//#ifdef UEP_VARIANT_2		//Mask贴图
				float4 _MaskTex_ST;
				float _MaskSmoothstepMin,_MaskSmoothstepMax,_MaskRotSpeed,_Mask_Offset_Xspeed,_Mask_Offset_Yspeed,_MaskRot;
                half _MaskScale;
				int _MaskMode, _MaskOnly;
			//#endif
			//#ifdef UEP_VARIANT_1		//Warp
				float4 _WarpTex_ST;
				float _WarpRot,_WarpRotSpeed,_Warp_Offset_Xspeed,_Warp_Offset_Yspeed,_Warp_Intensity,_WarpMove;
			//#endif
			//#ifdef UEP_VARIANT_6		//ColorTex
				float4 _ColorTex_ST;
				float _ColorRot,_ColorMoveSpdX,_ColorRotSpd;
			//#endif
			//#ifdef UEP_VARIANT_5		//DirectionTwo双向扰乱
				float _DiffSmoothMin, _DiffSmoothMax;
				int _DirectionEnum; 
			//#endif
                fixed _AlphaClipThreshold;
            CBUFFER_END

            // 旋转
            float2 Unity_Rotate_Degrees_float(float2 UV, float2 Center, float Rotation)
            {
                Rotation = Rotation * (3.1415926f / 180.0f);
                UV -= Center;
                float s = sin(Rotation);
                float c = cos(Rotation);
                fixed2x2 rMatrix = fixed2x2(c, -s, s, c);
                rMatrix *= 0.5;
                rMatrix += 0.5;
                rMatrix = rMatrix * 2 - 1;
                UV.xy = mul(UV.xy, rMatrix);
                UV += Center;
                return UV;
            }

            // 极坐标
            fixed2 Unity_PolarCoordinates_float(float2 UV, float2 Center, float RadialScale,float RadialOffset ,float LengthScale,float LengthOffset)
            {
                float2 delta = UV - Center;
                float len = length(delta);
                float radius = len * 2 * RadialScale + RadialOffset;
                float angle = atan2(delta.x, delta.y) * 1.0 / 6.28 * LengthScale + LengthOffset;
                angle += pow((1.7 - len), _BendStrength) * _TwistStrength;
                return float2(radius, angle);
            }

            // 扭曲
            float2 UV_Swirl(float2 UV, float2 Center)
            {
                float len = length(UV - Center);
                len = pow(len,_BendStrength);
                float angle = len * _TwistStrength;

                float s = sin(angle);
                float c = cos(angle);
                UV -= Center;
                float x = c * UV.x - s * UV.y;
                float y = s * UV.x + c * UV.y;
                return float2(x,y) + Center;
            }

            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                o.uv0.xy = v.uv;
                o.vertexColor = v.vertexColor;
                o.uv0.zw = v.vertex.xy;
				#ifdef UEP_VARIANT_6
					o.uv1.xy = TRANSFORM_TEX(v.uv, _ColorTex);
				#endif
                o.clipPos = UnityObjectToClipPos(v.vertex.xyz);
                return o;
            }

            float4 frag(VertexOutput i) : SV_Target  //fixed facing : VFACE
            {
                fixed4 vertexColor = i.vertexColor;

                float color_a = 1;

                #ifdef UNITY_UI_CLIP_RECT
                    color_a *= UnityGet2DClipping(i.uv0.zw, _ClipRect);
                    if ((color_a + _Color.a + vertexColor.a) < 0.001)
                    {
                        return 0;
                    }
                #else
                    if ((_Color.a + vertexColor.a) < 0.001)
                    {
                    return 0;
                    }
                #endif

                //Coordinate convert 
                //_M_Rot_Center_Y = 1 - _M_Rot_Center_Y;
                //_MainTex_ST.w = -_MainTex_ST.w;
                //_MaskTex_ST.w = -_MaskTex_ST.w;
                //#if UEP_VARIANT_1
                //    fixed2 uv2 = i.uv0;
                //#endif

                #ifdef UEP_VARIANT_2  // Mask贴图
                    float2 uv3 = i.uv0;
                    uv3 = uv3 + _MaskTex_ST.zw + _Time.y * float2(_Mask_Offset_Xspeed, _Mask_Offset_Yspeed);
                    uv3 = uv3 * _MaskTex_ST.xy;
                    uv3 = Unity_Rotate_Degrees_float((uv3-0.5f)*_MaskScale+0.5f, float2(_M_Rot_Center_X, _M_Rot_Center_Y), _MaskRot + _Time.y * _MaskRotSpeed);

                    fixed4 MaskTex_color = tex2D(_MaskTex, uv3);
                    float Mask_Value = min(MaskTex_color.r, MaskTex_color.a);
                    Mask_Value = lerp(Mask_Value, MaskTex_color.a, _MaskOnly);
                    Mask_Value = smoothstep(_MaskSmoothstepMin, _MaskSmoothstepMax, Mask_Value);
                    if (_MaskMode == 0)
                    {
                        #ifdef UNITY_UI_ALPHACLIP                        
                            clip(Mask_Value - _AlphaClipThreshold);
                        #else
                            if (Mask_Value < 0.001)
                            {
                                return 0;
                            }
                        #endif
                    }
                #else
                    fixed4 Mask_Value = fixed4(1,1,1,1);
                #endif
                float2 uv0 = i.uv0;
                #ifdef UEP_VARIANT_4		// MAINPOLAR 主贴图极坐标
                    uv0 = Unity_Rotate_Degrees_float(uv0,float2(_M_Rot_Center_X,_M_Rot_Center_Y),_MainTexRot + _Time.y * _MainTexRotSpeed);
                    uv0 = Unity_PolarCoordinates_float(uv0, float2(_M_Rot_Center_X,_M_Rot_Center_Y), _MainTex_ST.x, _MainTex_ST.z + _Time.y * _M_Offset_Xspeed,_MainTex_ST.y,_MainTex_ST.w + _Time.y * _M_Offset_Yspeed);
                #else 
                    uv0 = Unity_Rotate_Degrees_float(uv0,float2(_M_Rot_Center_X,_M_Rot_Center_Y),_MainTexRot + _Time.y * _MainTexRotSpeed);
                    uv0 = UV_Swirl(uv0,float2(_M_Rot_Center_X,_M_Rot_Center_Y));
                    uv0 = uv0 + _MainTex_ST.zw + _Time.y * float2(_M_Offset_Xspeed,_M_Offset_Yspeed);
                    uv0 = uv0 * _MainTex_ST.xy;
                #endif

                #ifdef UEP_VARIANT_1
					fixed2 uv2 = i.uv0;
                    //_WarpTex_ST.w = -_WarpTex_ST.w;
                    #ifdef  UEP_VARIANT_3
                        uv2 = Unity_Rotate_Degrees_float(uv2,float2(_M_Rot_Center_X,_M_Rot_Center_Y),_WarpRot + _Time.y * _WarpRotSpeed);
                        uv2 = Unity_PolarCoordinates_float(uv2, float2(_M_Rot_Center_X,_M_Rot_Center_Y), _WarpTex_ST.x, _WarpTex_ST.z + _Time.y * _Warp_Offset_Xspeed,_WarpTex_ST.y,_WarpTex_ST.w + _Time.y * _Warp_Offset_Yspeed);
                    #else
                        float2 param_enum = 1;
                        #ifdef UEP_VARIANT_5	//双向扰动
                            float2 xy = smoothstep(_DiffSmoothMin, _DiffSmoothMax, i.uv0.xy);
                            float4 param_speed_intensity = float4((step(xy,0.5) - 0.5) * 2,(xy - 0.5) * 2);		//param	xy:speed zw:intensity
                            param_enum = (1 - _DirectionEnum) * param_speed_intensity.xz + _DirectionEnum * param_speed_intensity.yw;	//param x:speed y:intensity
                            _Warp_Intensity *= param_enum.y;
                        #endif
                        uv2 = Unity_Rotate_Degrees_float(uv2,float2(_M_Rot_Center_X,_M_Rot_Center_Y),_WarpRot + _Time.y * _WarpRotSpeed);
                        uv2 = UV_Swirl(uv2,float2(_M_Rot_Center_X,_M_Rot_Center_Y));
                        uv2 = uv2 + _WarpTex_ST.zw + _Time.y * float2(_Warp_Offset_Xspeed,_Warp_Offset_Yspeed) * param_enum.x;
                        uv2 = uv2 * _WarpTex_ST.xy;
                    #endif


                    float Warp_tex = tex2D(_WarpTex, uv2);
					#ifdef UEP_VARIANT_2
						if (_MaskMode == 1)
						{
							Warp_tex *= Mask_Value;
						}
					#endif

                    fixed2 Warp = uv0 + ((Warp_tex - _WarpMove) * _Warp_Intensity);
                    fixed4 MainTex_color = tex2D(_MainTex, Warp);

                #else
                    fixed4 MainTex_color = tex2D(_MainTex, uv0);
                #endif
                #ifdef UNITY_UI_ALPHACLIP
                    clip(MainTex_color.a - _AlphaClipThreshold);
                #else
                    if (MainTex_color.a < 0.001)
                    {
                        return 0;
                    }
                #endif
                if (_RasAlpha) {

                    MainTex_color.a = MainTex_color.r;
                }

                //----------------------------------------------------------------------------------------------------------
                color_a *= MainTex_color.a * _Color.a;
                #ifdef UEP_VARIANT_2  // Mask贴图
                    if (_MaskMode == 0)
                    {
                        color_a *= Mask_Value;
                    }
                #endif
                float3 color_rgb = MainTex_color.rgb * _Color.rgb;
                //----------------------------------------------------------------------------------------------------------
                //return fixed4(Unity_Rotate_Degrees_fixed(uv4,0.5,1.5),0,1);
                //return color_a * vertexColor.a;
				#ifdef UEP_VARIANT_6
					//float2 color_rotate_uv = Unity_Rotate_Degrees_float(i.uv1.xy, float2(0.5, 0.5)*_ColorTex_ST.xy+_ColorTex_ST.zw, _ColorRot+_ColorRotSpd*_Time.y);
					float2 color_rotate_uv = Unity_Rotate_Degrees_float(i.uv1.xy, float2(_M_Rot_Center_X,_M_Rot_Center_Y), _ColorRot+_ColorRotSpd*_Time.y);
					float3 color_tex_rgb = tex2D(_ColorTex, color_rotate_uv+float2(_Time.y*_ColorMoveSpdX,0)).rgb;
					color_rgb *= color_tex_rgb;
				#endif

				color_rgb *= vertexColor.rgb;
				color_a *= vertexColor.a;
                return  float4(color_rgb, color_a);
            }
            ENDHLSL
        }
	}
	CustomEditor "EffectUEPUVTransform"
}
