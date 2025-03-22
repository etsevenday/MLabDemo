//https://lilithgames.feishu.cn/wiki/wikcnGv333cuG71D2p73LiYFFPg
//written by MaoShu
//2022.06.09
//Universl Pure Particle 
//ver 2.1 KeyWord调整

Shader "UEP/Universal/ParticlePure"
{
    Properties
    {
        [Space(15)]//FirstParticle 
        [Header(First Particle)]
        _MainTex ("Main Tex", 2D) = "black"{}
        _FirstTex_ST("First Tex ST",Vector) = (1,1,0,0)
        [HDR]_MainColor ("Main Color", Color) = (1,1,1,1) 
        _FirstParticle ("First Particle Param" , Vector) = (0,0,0,1)
        
        [Space(15)]//SecondParticle
        [Header(Second Particle)]
        _SecondTex ("Second Tex", 2D) = "black"{}
        _SecondParticle ("Second Particle Param" , Vector) = (0,0,0,1)

        [Space(15)]//ThirdParticle
        [Header(Third Particle)]
        _ThirdTex ("Third Tex", 2D) = "black"{}
        _ThirdParticle ("Third Particle Param" , Vector) = (0,0,0,1)

        [Space(15)]//Base
        _NoiseTex ("Noise Tex",2D) = "white"{}
        _NoiseIntensity("Noise Intensity", float) = 0.2
        _MaskTex ("Mask Tex(RGB)",2D) = "white"{}

        [Space(15)]//Seting
        [KeywordEnum(AlphaBlend,Additive,AddEx)] _Blend("Blend mode", int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("SrcBlend", int) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("DstBlend", int) = 10
		[Enum(UnityEngine.Rendering.BlendOp)] _BlendOp("BlendOp", int) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull", int) = 2
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", int) = 0
        [Toggle]_ZWrite("ZWrite", Int) = 0
        
        //[HideInInspector]_GammaRadio("Gamma Radio", Float) = 1
        [HideInInspector]_StencilComp ("Stencil Comparison", Float) = 8
        [HideInInspector]_Stencil ("Stencil ID", Float) = 0
        [HideInInspector]_StencilOp ("Stencil Operation", Float) = 0
        [HideInInspector]_StencilWriteMask ("Stencil Write Mask", Float) = 255
        [HideInInspector]_StencilReadMask ("Stencil Read Mask", Float) = 255

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

        Blend [_SrcBlend][_DstBlend] //SrcAlpha OneMinusSrcAlpha
        ZWrite [_ZWrite]
        ZTest [_ZTest]

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma shader_feature_local __ UEP_VARIANT_1       //第二层效果
            #pragma shader_feature_local __ UEP_VARIANT_2       //第三层效果
            #pragma multi_compile __ UNITY_UI_CLIP_RECT  //Canvas Clip

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"
			//#include "../../uds/Codes/Common/ColorCommon.cginc"

            struct appdata
            {
                half4  vertex  : POSITION;
                fixed4 color   : COLOR;
                float2 uv      : TEXCOORD0;
                
            };

            struct v2f
            {
                float4 uv       : TEXCOORD0;
                half4  vertex   : SV_POSITION;
                half4  uv1      : TEXCOORD1;
                fixed4 color    : Color;
            };

            sampler2D _NoiseTex,_MaskTex,_MainTex;
			#ifdef UEP_VARIANT_1
				sampler2D _SecondTex;
			#endif
			#ifdef UEP_VARIANT_2
				sampler2D _ThirdTex;
			#endif
			CBUFFER_START(UnityPerMaterial)
				float4 _NoiseTex_ST,_MaskTex_ST,_MainTex_ST,_SecondTex_ST,_ThirdTex_ST;
				fixed4 _MainColor,_FirstParticle,_SecondParticle,_ThirdParticle;
				fixed _NoiseIntensity;
			CBUFFER_END
			fixed4 _ClipRect;
            
            float2 Unity_Rotate_Radians_float(float2 UV , float Rotation)
            {
                //Unity官方旋转uv算法
                half Center = half2(0.5,0.5);
                UV -= Center;
                float s = sin(Rotation);
                float c = cos(Rotation);
                float2x2 rMatrix = float2x2(c, -s, s, c);
                UV.xy = mul(UV.xy, rMatrix);
                UV += Center;
                return UV;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.color = v.color;
                o.uv.xy = v.uv;
                o.uv.zw = TRANSFORM_TEX(v.uv, _NoiseTex);
                o.uv1.xy = v.vertex.xy;
                o.uv1.zw = TRANSFORM_TEX(v.uv, _MaskTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

             #ifdef UNITY_UI_CLIP_RECT
                fixed out_ahlpha = UnityGet2DClipping(i.uv1.xy,_ClipRect);
                if(out_ahlpha < 0.001)
                {
                    return 0;
                }
             #endif

                if(i.color.a + _MainColor.a < 0.001)
                {
                    return 0;
                }

                //三通道Mask，R通道：整体mask，G通道：第二层及第三层mask，B通道：第三层mask
                fixed3 mask_tex = tex2D(_MaskTex, i.uv1.zw).rgb;
                half noise_tex = smoothstep(0,1,tex2D(_NoiseTex, i.uv.zw ).r) * _NoiseIntensity;

                //第一层粒子
                half first_noise = noise_tex  + _FirstParticle.z;
                float2 first_uv = Unity_Rotate_Radians_float( i.uv.xy , first_noise);
                first_uv = first_uv * _MainTex_ST.xy + _MainTex_ST.zw + float2(_FirstParticle.x , _FirstParticle.y)* _Time.y; 
                fixed3 first_tex_col = tex2D(_MainTex, first_uv).rgb * _FirstParticle.w * mask_tex.r;
                fixed4 col = fixed4(first_tex_col, 1);

             #ifdef UEP_VARIANT_1   
                //第二层粒子
                half second_noise = noise_tex + _SecondParticle.z;
                float2 second_uv = Unity_Rotate_Radians_float( i.uv.xy , second_noise);
                second_uv = second_uv * _SecondTex_ST.xy + _SecondTex_ST.zw + float2(_SecondParticle.x , _SecondParticle.y)* _Time.y;
                fixed3 second_tex_col = tex2D(_SecondTex, second_uv).rgb * _SecondParticle.w * mask_tex.r * mask_tex.g;
                col.rgb += second_tex_col;
             #endif

             #ifdef UEP_VARIANT_2
                //第三层粒子
                half third_noise = noise_tex + _ThirdParticle.z;
                float2 third_uv = Unity_Rotate_Radians_float( i.uv.xy , third_noise);
                third_uv = third_uv * _ThirdTex_ST.xy + _ThirdTex_ST.zw + float2(_ThirdParticle.x , _ThirdParticle.y)* _Time.y;
                fixed3 third_tex_col = tex2D(_ThirdTex, third_uv).rgb * _ThirdParticle.w * mask_tex.r * mask_tex.b;
                col.rgb += third_tex_col;
             #endif

                col *= i.color * _MainColor;

                //颜色矫正
				//col.rgb = CommonColorConvert(col.rgb);
				//col.a = CommonAlphaConvert(col.a, 1);

                return col;
            }
            ENDCG
        }
    }
    CustomEditor"EffectUEPParticlePure"
}
