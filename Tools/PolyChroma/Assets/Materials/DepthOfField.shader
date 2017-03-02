Shader "Custon/DepthOfField" {
	Properties {
		_MainTex ("Screen Blended", 2D) = "" {}
		_ColorBuffer ("Color", 2D) = "" {}
	}
	
	CGINCLUDE

	#include "UnityCG.cginc"
	
	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv[2] : TEXCOORD0;
	};
			
	sampler2D _ColorBuffer;
	sampler2D _MainTex;
	sampler2D _OldTex;

	half _Intensity;
	half4 _ColorBuffer_TexelSize;
	half4 _ColorBuffer_ST;
	half4 _MainTex_TexelSize;
	half4 _MainTex_ST;	

	half4 _Offsets;

	half _TrailAlpha;
	half _StretchWidth;
	half2 _Threshhold;
	half _Saturation;

	v2f vert( appdata_img v ) {
		v2f o;
		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		o.uv[0] = v.texcoord.xy;
		o.uv[1] = v.texcoord.xy;
		
		#if UNITY_UV_STARTS_AT_TOP
		if (_ColorBuffer_TexelSize.y < 0) 
			o.uv[1].y = 1-o.uv[1].y;
		#endif	

		return o;
	}

	half4 fragBlend (v2f i) : SV_Target {
		return tex2D(_MainTex, i.uv[0].xy);
	}

	half4 fragCopy (v2f i) : SV_Target {
		return tex2D(_MainTex, i.uv[0].xy);
	}

	half4 fragAdd (v2f i) : SV_Target {
		return tex2D(_MainTex, i.uv[0].xy) * _Intensity;
	}

	half4 fragToneDown (v2f i) : SV_Target {
		return tex2D(_MainTex, i.uv[0].xy) - 0.5;
	}

	half4 fragTrailBlend (v2f i) : SV_Target {
		fixed4 c1 = tex2D(_MainTex, i.uv[0].xy);
		fixed4 c2 = tex2D(_OldTex, i.uv[0].xy) * _TrailAlpha - 1/255.0;
		fixed4 c = max(c1, c2);
		return c;
	}


	struct v2f_blur {
		half4 pos : SV_POSITION;
		half2 uv : TEXCOORD0;
		half4 uv01 : TEXCOORD1;
		half4 uv23 : TEXCOORD2;
		half4 uv45 : TEXCOORD3;
		half4 uv67 : TEXCOORD4;
	};

	v2f_blur vertWithMultiCoords2 (appdata_img v) {
		v2f_blur o;
		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		o.uv.xy = UnityStereoScreenSpaceUVAdjust(v.texcoord.xy, _MainTex_ST);
		o.uv01 =  UnityStereoScreenSpaceUVAdjust(v.texcoord.xyxy + _Offsets.xyxy * half4(1,1, -1,-1), _MainTex_ST);
		o.uv23 =  UnityStereoScreenSpaceUVAdjust(v.texcoord.xyxy + _Offsets.xyxy * half4(1,1, -1,-1) * 2.0, _MainTex_ST);
		o.uv45 =  UnityStereoScreenSpaceUVAdjust(v.texcoord.xyxy + _Offsets.xyxy * half4(1,1, -1,-1) * 3.0, _MainTex_ST);
		o.uv67 =  UnityStereoScreenSpaceUVAdjust(v.texcoord.xyxy + _Offsets.xyxy * half4(1,1, -1,-1) * 4.0, _MainTex_ST);
		o.uv67 =  UnityStereoScreenSpaceUVAdjust(v.texcoord.xyxy + _Offsets.xyxy * half4(1,1, -1,-1) * 5.0, _MainTex_ST);
		return o;  
	}

	half4 fragBlur (v2f_blur i) : SV_Target {
		half4 color = half4 (0,0,0,0);
		color += 0.225 * tex2D (_MainTex, i.uv);
		color += 0.150 * tex2D (_MainTex, i.uv01.xy);
		color += 0.150 * tex2D (_MainTex, i.uv01.zw);
		color += 0.110 * tex2D (_MainTex, i.uv23.xy);
		color += 0.110 * tex2D (_MainTex, i.uv23.zw);
		color += 0.075 * tex2D (_MainTex, i.uv45.xy);
		color += 0.075 * tex2D (_MainTex, i.uv45.zw);	
		color += 0.0525 * tex2D (_MainTex, i.uv67.xy);
		color += 0.0525 * tex2D (_MainTex, i.uv67.zw);
		return color;
	}

	half4 fragBlurWithAlpha (v2f_blur i) : SV_Target {
		half4 color = half4 (0,0,0,0);
		fixed4 c;

		c = tex2D (_MainTex, i.uv);
		color += 0.225 * fixed4(c.rgb * c.a, c.a);
		c = tex2D (_MainTex, i.uv01.xy);
		color += 0.150 * fixed4(c.rgb * c.a, c.a);
		c = tex2D (_MainTex, i.uv01.zw);
		color += 0.150 * fixed4(c.rgb * c.a, c.a);
		c = tex2D (_MainTex, i.uv23.xy);
		color += 0.110 * fixed4(c.rgb * c.a, c.a);
		c = tex2D (_MainTex, i.uv23.zw);
		color += 0.110 * fixed4(c.rgb * c.a, c.a);
		c = tex2D (_MainTex, i.uv45.xy);
		color += 0.075 * fixed4(c.rgb * c.a, c.a);
		c = tex2D (_MainTex, i.uv45.zw);
		color += 0.075 * fixed4(c.rgb * c.a, c.a);	
		c = tex2D (_MainTex, i.uv45.xy);
		color += 0.0525 * fixed4(c.rgb * c.a, c.a);
		c = tex2D (_MainTex, i.uv45.zw);
		color += 0.0525 * fixed4(c.rgb * c.a, c.a);
		c = tex2D (_MainTex, i.uv);
		color.rgb = color.rgb / color.a;
		return color;
	}

	ENDCG 
	
Subshader {
	  ZTest Always Cull Off ZWrite Off

 // 0: 通常のブレンド
 Pass {    

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment fragBlend
      ENDCG
  }

 // 1: トーンマップ
 Pass {    
 	Blend SrcAlpha OneMinusSrcAlpha
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment fragCopy
      ENDCG
  }

 // 2: Blur
 Pass {    

      CGPROGRAM
      #pragma vertex vertWithMultiCoords2
      #pragma fragment fragBlur
      ENDCG
  }
 // 3: 加算
 Pass {    
 	  Blend One One

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment fragAdd
      ENDCG
  }

 // 4: アルファつきBlur
 Pass {    

      CGPROGRAM
      #pragma vertex vertWithMultiCoords2
      #pragma fragment fragBlurWithAlpha
      ENDCG
  }

 // 5: 航跡ブレンド
 Pass {    
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment fragTrailBlend
      ENDCG
  }
}

Fallback off
	
} // shader
