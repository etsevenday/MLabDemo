Shader "UEP/Universal/StencilLattice"
{
    Properties
    {
        [PerRendererData] _MainTex("_MainTex", 2D) = "white" {}
        [Toggle(UNITY_UI_USEMASK)] _UseMask ("Use Mask", Float) = 0
        _MaskTex("_MaskTex",2D) = "white" {}
        _MaskRange("_MaskRange",float) = 1
        [Toggle(UEP_VARIANT_2)] _UseDetail("Use Detail", Float) = 0
        _DetailTex("_DetailTex",2D) = "white"{}
        _DetailRange("_DetailRange",float) = 0
        _CanvasGroupAlpha("Alpha",Range(0, 1)) = 0.5
        _Num("LatticeNum",Range(0, 1)) = 0.5
        [Space(20)]
        [Toggle]_ZWrite("ZWrite",float) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)]_ZTest("ZTest",int)=4
        [Space(20)]
		_StencilID("Stencil ID", float) = 128
		[Enum(UnityEngine.Rendering.CompareFunction)] _CompFunc("Compare Function", int) = 8
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilOp("Stencil Option", int) = 2        
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Transparent" 
            "Queue" = "Transparent"
        }
        BLEND SrcAlpha OneMinusSrcAlpha
        ZWrite [_ZWrite]
        ZTest [_ZTest]
		Stencil
		{
			Ref [_StencilID]
			Comp [_CompFunc]
			Pass [_StencilOp]
			Fail Keep
		}

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #pragma multi_compile_local _ UNITY_UI_USEMASK					//开启遮罩图
            #pragma shader_feature_local __ UEP_VARIANT_2					//开启细节图
            

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD2;
                float2 uv : TEXCOORD;
            };

            half _CanvasGroupAlpha,_Num, _MaskRange,_DetailRange;
            sampler2D _MainTex;
            float4 _DetailTex_ST;
            sampler2D  _DetailTex, _MaskTex;

            float isDithered(float2 pos, float alpha)
            {
                half m = max(_ScreenParams.x, _ScreenParams.y);
	            half downScale = max(0.25, 1.0 - floor(m / 1500) * 0.5);
                pos *=800;
                pos  = float2(pos.x/(_ScreenParams.y/ _ScreenParams.x),pos.y);
                pos = floor(pos);
                const float DITHER_THRESHOLDS[16] =
                {
                    1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
                    13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
                    4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
                    16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
                };
    
                float index = fmod(pos.x, 4.0) * 4.0 + fmod(pos.y, 4.0);
                return alpha - DITHER_THRESHOLDS[index];
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 screenUV = i.screenPos.xy / i.screenPos.w;  //屏幕UV	
                half mainAlpha = tex2D(_MainTex, i.uv).a;
                half clipvalue = _CanvasGroupAlpha * mainAlpha;
                #ifdef UNITY_UI_USEMASK
                    half mask = tex2D(_MaskTex,i.uv);
                    clipvalue *= mask * _MaskRange - 0.001;
                #endif

                #ifdef UEP_VARIANT_2
                    half detailtex = tex2D(_DetailTex, i.uv * _DetailTex_ST.xy + _DetailTex_ST.zw).r + _DetailRange;
                    clip( clipvalue - detailtex - 0.001);
                #else
                    clip(isDithered(screenUV* _Num, clipvalue));
                #endif
                return 0;
            }
            ENDCG
        }
    }
}
