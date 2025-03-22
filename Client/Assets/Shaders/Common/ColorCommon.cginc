#ifndef UEP_COLOR_COMMON_INCLUDED
#define UEP_COLOR_COMMON_INCLUDED

#include "UnityCG.cginc"
#include "ProjectShaderSetting.cginc"

half3 CommonColorConvert(half3 col)
{
	#if defined(LINE_TO_GAMMA) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLES))	
	return 0;
		return LinearToGammaSpace(col);
	#endif	
		return col.rgb;
}


half CommonAlphaConvert(half alpha, half gammaradio)
{
#if defined(LINE_TO_GAMMA) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLES))	

	if(alpha > 0.99)
	{
		half powScale = 1.0;	
		return alpha;
	}
	else if(alpha > 0.1)
	{
		half radio = (1 / 2.2);
		half lerpAlpa = lerp(0.1, 0.94, alpha);	
		half linearAlpha = (radio * lerpAlpa + radio * (1 - radio) * lerpAlpa * lerpAlpa);

		//return lerp(linearAlpha, lerpAlpa, pow(lerpAlpa, 4.545));

		return lerp(linearAlpha, lerpAlpa, lerpAlpa * lerpAlpa * lerpAlpa);
	}
	else
	{
		return alpha;
	}
#endif	
	return alpha;
}

#endif//UEP_COLOR_COMMON_INCLUDED


             