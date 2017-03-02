using System;
using UnityEngine;
using UnityStandardAssets.ImageEffects;

[ExecuteInEditMode]
[RequireComponent (typeof(Camera))]
public class DepthOfFieldImageEffect : PostEffectsBase
{
	public Shader tonemapShader;
	private Material tonemapMaterial;

	public Shader screenBlendShader;
	private Material screenBlend;

	public int bloomBlurIterations = 2;
	public float bloomIntensity = 3;
	public float sepBlurSpread = 10;

	public bool BloomEnable = true;

	public bool BloomTrail = true;

	public RenderTexture nearTexture;
	public RenderTexture farTexture;

	public override bool CheckResources ()
	{
		CheckSupport (false);

		screenBlend = CheckShaderAndCreateMaterial (screenBlendShader, screenBlend);
		tonemapMaterial = CheckShaderAndCreateMaterial(tonemapShader,tonemapMaterial);

		if (!isSupported)
			ReportAutoDisable ();
		return isSupported;
	}

	public void OnRenderImage (RenderTexture source, RenderTexture destination)
	{
		if (CheckResources()==false)
		{
			Graphics.Blit (source, destination);
			return;
		}

		var temp0 = Blur (farTexture, false);
		Graphics.Blit (temp0, destination);
		RenderTexture.ReleaseTemporary (temp0);

		Graphics.Blit (source, destination, screenBlend, 1);

		var temp = Blur (nearTexture, true);
		Graphics.Blit (temp, destination, screenBlend, 1);
		RenderTexture.ReleaseTemporary (temp);
	}

	RenderTexture Blur(RenderTexture source, bool withAlpha){
		// ブルーム処理
		var rtFormat= RenderTextureFormat.Default;
		var rtW2= source.width/1;
		var rtH2= source.height/1;
		var rtW4= source.width/1;
		var rtH4= source.height/1;

		RenderTexture quarterRezColor = RenderTexture.GetTemporary (rtW4, rtH4, 0, rtFormat);
		RenderTexture halfRezColorDown = RenderTexture.GetTemporary (rtW2, rtH2, 0, rtFormat);
		Graphics.Blit (source, halfRezColorDown);
		Graphics.Blit (halfRezColorDown, quarterRezColor);
		RenderTexture.ReleaseTemporary (halfRezColorDown);

		float widthOverHeight = (1.0f * source.width) / (1.0f * source.height);
		float oneOverBaseSize = 1.0f / 512.0f;

		RenderTexture secondQuarterRezColor = RenderTexture.GetTemporary (rtW4, rtH4, 0, rtFormat);
		Graphics.Blit (quarterRezColor, secondQuarterRezColor);

		if (bloomBlurIterations < 1) bloomBlurIterations = 1;
		else if (bloomBlurIterations > 10) bloomBlurIterations = 10;

		for (int iter = 0; iter < bloomBlurIterations; iter++)
		{
			float spreadForPass = (1.0f + (iter * 0.25f)) * sepBlurSpread;

			// vertical blur
			RenderTexture blur4 = RenderTexture.GetTemporary (rtW4, rtH4, 0, rtFormat);
			screenBlend.SetVector ("_Offsets", new Vector4 (0.0f, spreadForPass * oneOverBaseSize, 0.0f, 0.0f));
			Graphics.Blit (secondQuarterRezColor, blur4, screenBlend, withAlpha ? 4 : 2 /* blur */);
			RenderTexture.ReleaseTemporary(secondQuarterRezColor);
			secondQuarterRezColor = blur4;

			// horizontal blur
			blur4 = RenderTexture.GetTemporary (rtW4, rtH4, 0, rtFormat);
			screenBlend.SetVector ("_Offsets", new Vector4 ((spreadForPass / widthOverHeight) * oneOverBaseSize, 0.0f, 0.0f, 0.0f));
			Graphics.Blit (secondQuarterRezColor, blur4, screenBlend, withAlpha ? 4 : 2 /* blur */);
			RenderTexture.ReleaseTemporary (secondQuarterRezColor);
			secondQuarterRezColor = blur4;
		}

		RenderTexture.ReleaseTemporary (quarterRezColor);

		//RenderTexture.ReleaseTemporary (secondQuarterRezColor);
		return secondQuarterRezColor;
	}

}
