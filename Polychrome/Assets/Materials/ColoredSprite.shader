Shader "Custom/ColoredSprite"
{
	Properties
	{
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		_Color ("Tint", Color) = (1,1,1,1)
		[MaterialToggle] PixelSnap ("Pixel snap", Float) = 0
	}

	SubShader
	{
		Tags
		{ 
			"Queue"="Transparent"
			"IgnoreProjector"="True" 
			"RenderType"="Transparent"
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}

		Cull Off
		Lighting Off
		ZWrite On // Zバッファ描画のため追記
		Blend One OneMinusSrcAlpha

		Pass
		{
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile _ PIXELSNAP_ON
			#pragma multi_compile _ ETC1_EXTERNAL_ALPHA
			#include "UnityCG.cginc"
			
			struct appdata_t
			{
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				float2 texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				fixed4 color    : COLOR;
				float2 texcoord  : TEXCOORD0;
				float2 screenPos : TEXCOORD1; // Add
				UNITY_VERTEX_OUTPUT_STEREO
			};
			
			fixed4 _Color;

			v2f vert(appdata_t IN)
			{
				v2f OUT;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
				OUT.vertex = UnityObjectToClipPos(IN.vertex);
				float4 sPos = mul(UNITY_MATRIX_MVP, IN.vertex); // Add
			    OUT.screenPos = sPos.xy / sPos.w / 2 + 0.5; // Add 
				OUT.texcoord = IN.texcoord;
				OUT.color = IN.color * _Color;
				#ifdef PIXELSNAP_ON
				OUT.vertex = UnityPixelSnap (OUT.vertex);
				#endif

				return OUT;
			}

			sampler2D _MainTex;
			sampler2D _AlphaTex;
			sampler2D _HPowerTex; // 追加
			sampler2D _LightTex; // 追加

			#include "ColoredCommon.cginc"

			fixed4 SampleSpriteTexture (float2 uv)
			{
				fixed4 color = tex2D (_MainTex, uv);

#if ETC1_EXTERNAL_ALPHA
				// get the color from an external texture (usecase: Alpha support for ETC1 on android)
				color.a = tex2D (_AlphaTex, uv).r;
#endif //ETC1_EXTERNAL_ALPHA

				return color;
			}

			fixed4 frag(v2f IN) : SV_Target
			{
				fixed4 c = SampleSpriteTexture (IN.texcoord) * IN.color;

				fixed4 hsv = RGBToHSV(c);
				fixed power = tex2D(_HPowerTex, fixed2(hsv.r,0)).a;
				fixed4 light = tex2D(_LightTex, IN.screenPos);
				power = power + light.r * 2;
				hsv.g = hsv.g * power;
				hsv.b += light.b * 0.7;
				//hsv.g = 1;
				//hsv.b = 1;


				c = HSVToRGB(hsv);
				// カラフルなところだけ明るくなる
				if( hsv.g > 0.01 ){
					c.rgb = c.rgb * (0.5 + power * 0.5);
				}else{
					c.rgb = c.rgb * 0.5;
				}
				
				//c.rgb = c.rgb * 0.5;

				c.rgb *= c.a;

				clip(c.a - 0.5);

				return c;
			}
		ENDCG
		}
	}
}
