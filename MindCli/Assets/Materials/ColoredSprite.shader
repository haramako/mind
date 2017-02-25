Shader "Custom/ColoredSprite"
{
	Properties
	{
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		/*[PerRendererData]*/ _HPowerTex ("HSV Power Texture", 2D) = "white" {}
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
		ZWrite Off
		Blend One OneMinusSrcAlpha

		Pass
		{
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
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
				UNITY_VERTEX_OUTPUT_STEREO
			};
			
			fixed4 _Color;

			v2f vert(appdata_t IN)
			{
				v2f OUT;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
				OUT.vertex = UnityObjectToClipPos(IN.vertex);
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

			// RGBをHSVに変換する
			// 帰り値の HSVA は RGBA に対応する
			fixed4 RGBToHSV(fixed4 c){
				fixed max_ = max(max(c.r, c.g), c.b);
				fixed min_ = min(min(c.r, c.g), c.b);
				fixed diff = max_ - min_;
				fixed4 hsv;
				if( min_ == c.b ){
					hsv.r = 60/360.0 * (c.g - c.r) / diff + 60/360.0;
				}else if( min_ == c.r ){
					hsv.r = 60/360.0 * (c.b - c.g) / diff + 180/360.0;
				}else{
				 	hsv.r = 60/360.0 * (c.r - c.b) / diff + 300/360.0;
				}
				hsv.g = diff;
				hsv.b = max_;
				hsv.a = c.a;
				return hsv;
			}

			fixed4 HSVToRGB(fixed4 hsv){
				float h_ = hsv.r * 6.0;
				int h_int = floor(h_);
				fixed4 r;
				fixed c = hsv.g;
				fixed x = c * (1 - abs(h_ % 2 - 1));
				fixed vc = hsv.b - c;
				switch( h_int ){
				case 0:
					x = c * h_;
					return fixed4(vc + c, vc + x, vc    , hsv.a);
				case 1:
					x = c * (2 - h_);
					return fixed4(vc + x, vc + c, vc    , hsv.a);
				case 2:
					x = c * (-2 + h_);
					return fixed4(vc    , vc + c, vc + x, hsv.a);
				case 3:
					x = c * (4 - h_);
					return fixed4(vc    , vc + x, vc + c, hsv.a);
				case 4:
					x = c * (-4 + h_);
					return fixed4(vc + x, vc    , vc + c, hsv.a);
				case 5:
					x = c * (6 - h_);
					return fixed4(vc + c, vc    , vc + x, hsv.a);
				default:
					return 0;
				}
			}

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
				hsv.g = hsv.g * power;
				//hsv.g = 1;
				//hsv.b = 1;

				c = HSVToRGB(hsv);
				c.rgb = c.rgb * (0.5 + power * 0.5);
				//c.rgb = c.rgb * 0.5;

				c.rgb *= c.a;
				return c;
			}
		ENDCG
		}
	}
}
