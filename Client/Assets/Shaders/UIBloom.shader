// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)_test'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "UEP/Interface/UIBloom"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Bloom("Bloom", 2D) = "white" {}
		_BlurRadius("radius",float) = 1
	}
		CGINCLUDE
#include "UnityCG.cginc"
		struct v2f {
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
		};
			struct v2f_blur
		{
			float4 pos:SV_POSITION;
			float2 uv2[5] : TEXCOORD0;
		};

		struct v2f_simple {
			float4 pos : SV_POSITION;
			float4 uv : TEXCOORD0;
		};

		sampler2D _MainTex;
		sampler2D _Bloom;

		uniform float4 _ColorMix = 1;
		uniform float4 _MainTex_TexelSize;

		// x:模糊半径 y:未使用 z:变亮强度 w:Bloom阈值
		uniform float4 _Parameter;
		uniform float _ScaleX;
		uniform float _ScaleY;

		v2f vertExtractBright(appdata_img v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			//o.uv = v.texcoord;
			o.uv = (v.texcoord - 0.5) * float2(_ScaleX, _ScaleY) + 0.5;
			return o;
		}
		float luminance(float4 color) {
			return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
		}
		float4 fragExtractBright(v2f i) : SV_Target{
			clip(step(0, i.uv.x) * step(0, i.uv.y) * step(i.uv.x, 1) * step(i.uv.y, 1)- 0.01);
			float4 c = tex2D(_MainTex, i.uv);
			float val = clamp(luminance(c) - _Parameter.w, 0.0, 1.0);
			
			return c * _ColorMix * val;
		}

			v2f_simple vert(appdata_img v)
		{
			v2f_simple o;
			o.pos = UnityObjectToClipPos(v.vertex); 
			o.uv.xy = v.texcoord;
			//o.uv.xy = (v.texcoord - 0.5) * float2(_ScaleX, _ScaleY) + 0.5;
			return o;
		}
			float4 frag(v2f_simple i) : SV_Target
		{
			float4 col = float4(0,0,0,0);	//初始化色彩为黑色
			float2 offset = _Parameter.x * _MainTex_TexelSize;
			float G[9] = {		//设置卷积模板   此处是3*3的高斯模板
				1,2,1,
				2,4,2,
				1,2,1
			};
			for (int x = 0; x < 3; x++) {	//进行3*3高斯模板的卷积（加权求平均值）
				for (int y = 0; y < 3; y++) {
					float2 uv_offset = i.uv.xy + float2(x - 1, y - 1) * offset;
					//if (step(0, uv_offset.x) * step(0, uv_offset.y) * step(uv_offset.x, 1) * step(uv_offset.y, 1) > 0.1)
					{
						col += tex2D(_MainTex, float4(uv_offset, 0, 0)) * G[x * 1 + y * 3];
					}
					
				}
			}
			col = col / 16;
			//col.a = 1;
			return float4(col.rgb + col.rgb * _Parameter.z, col.a);
		}

			//考虑到D3D9的uv坐标Y轴是反转的，因此需要做个判断进行调整，防止图像倒转。
			v2f_simple vertBloom(appdata_img v)
		{
			v2f_simple o;
			o.pos = UnityObjectToClipPos(v.vertex); 
			o.uv.zw = v.texcoord.xy;
			v.texcoord.xy = (v.texcoord.xy - 0.5) * float2(_ScaleX, _ScaleY) + 0.5;
			o.uv.xy = v.texcoord.xy;
#if SHADER_API_D3D9
			if (_MainTex_TexelSize.y < 0.0)
				o.uv.w = 1.0 - o.uv.w;
#endif
			return o;
		}
		float4 fragBloom(v2f_simple i) : COLOR
		{
			float4 color = 0;
			if (step(0, i.uv.x) * step(0, i.uv.y) * step(i.uv.x, 1) * step(i.uv.y, 1) > 0.1)
			{
				color = tex2D(_MainTex, i.uv.xy);
			}
			
			color += tex2D(_Bloom, i.uv.zw);
			return float4(color.rgb, color.a);
		}

			//默认渲染
			v2f_simple vertDefault(appdata_img v)
		{
			v2f_simple o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv.xy = v.texcoord.xyxy;
#if SHADER_API_D3D9
			if (_MainTex_TexelSize.y < 0.0)
				o.uv.w = 1.0 - o.uv.w;
#endif
			return o;
		}
		float4 fragDefault(v2f_simple i) : COLOR
		{
			float4 color = 0;
			color = tex2D(_MainTex, i.uv.xy);
			color.a = 1;
			return color;
		}

		
			ENDCG
			SubShader
		{
			Cull Off ZWrite Off ZTest Always

			// 0
			Pass
			{
				Name "GetBright"
				CGPROGRAM
				#pragma vertex vertExtractBright
				#pragma fragment fragExtractBright

				ENDCG
			}
			// 1
			Pass
			{
				Name "Blur"
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				ENDCG
			}

			//2
			Pass
			{
				Name "Add"
				//Blend SrcAlpha One
				CGPROGRAM
				#pragma vertex vertDefault
				#pragma fragment fragDefault
				ENDCG
			}
		}
}
