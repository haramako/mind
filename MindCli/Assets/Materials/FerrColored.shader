Shader "Custom/Ferr/Colored" {
	Properties {
		_MainTex("Texture (RGBA)", 2D) = "white" {}
	}
	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"  }
		Blend SrcAlpha OneMinusSrcAlpha

		LOD 100
		Cull      Off
		Lighting  Off
		ZWrite    Off
		Fog {Mode Off}
		
		Pass {
			CGPROGRAM

			#pragma vertex         vert
			#pragma fragment       frag2
			#pragma fragmentoption ARB_precision_hint_fastest

			#include "ColoredCommon.cginc"
			#include "UnityCG.cginc"
			#include "../Ferr/2DTerrain/Shaders/Ferr2DTCommon.cginc"

			sampler2D _HPowerTex; // 追加

			fixed4 frag2(VS_OUT inp) : COLOR {
				fixed4 color = tex2D(_MainTex, inp.uv);
				#ifdef FERR2DT_LIGHTMAP
				fixed3 light = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, inp.lightuv));
				#elif  MAX_LIGHTS > 0
				fixed3 light = UNITY_LIGHTMODEL_AMBIENT;
				#endif

				color      = color * inp.color;
				#if MAX_LIGHTS > 0
				for (int i = 0; i < MAX_LIGHTS; i++) {
					light += GetLight(i, inp.viewpos);
				}

				#endif

				#if defined(FERR2DT_LIGHMAP) || MAX_LIGHTS > 0
				color.rgb *= light;
				#endif
				
				#if defined(FERR2DT_VERTEXLIT)
				color.rgb *= inp.light;
				#endif


				fixed4 hsv = RGBToHSV(color);
				fixed power = tex2D(_HPowerTex, fixed2(hsv.r,0)).a;
				hsv.g = hsv.g * power;

				color = HSVToRGB(hsv);
				if( hsv.g > 0.3 ){
					color.rgb = color.rgb * (0.5 + power * 0.5);
				}else{
					color.rgb = color.rgb * 0.5;
				}

				color.rgb *= color.a;

				clip(color.a - 0.5);


				return color;
			}

			ENDCG
		}
	}
}
