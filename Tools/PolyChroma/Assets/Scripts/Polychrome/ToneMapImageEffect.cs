using System;
using UnityEngine;
using UnityStandardAssets.ImageEffects;

[ExecuteInEditMode]
[RequireComponent (typeof(Camera))]
[AddComponentMenu ("Image Effects/ToneMap")]
public class ToneMapImageEffect : PostEffectsBase
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

	public RenderTexture oldBloom_;

	public override bool CheckResources ()
	{
		CheckSupport (false);

		screenBlend = CheckShaderAndCreateMaterial (screenBlendShader, screenBlend);
		tonemapMaterial = CheckShaderAndCreateMaterial(tonemapShader,tonemapMaterial);

		if (!isSupported)
			ReportAutoDisable ();
		return isSupported;
	}

	void BloomEffect(RenderTexture source, RenderTexture destination){
		// ブルーム処理
		var rtFormat= RenderTextureFormat.Default;
		var rtW2= source.width/2;
		var rtH2= source.height/2;
		var rtW4= source.width/4;
		var rtH4= source.height/4;

		RenderTexture quarterRezColor = RenderTexture.GetTemporary (rtW4, rtH4, 0, rtFormat);
		RenderTexture halfRezColorDown = RenderTexture.GetTemporary (rtW2, rtH2, 0, rtFormat);
		Graphics.Blit (source, halfRezColorDown);
		Graphics.Blit (halfRezColorDown, quarterRezColor);
		RenderTexture.ReleaseTemporary (halfRezColorDown);

		float widthOverHeight = (1.0f * source.width) / (1.0f * source.height);
		float oneOverBaseSize = 1.0f / 512.0f;

		RenderTexture secondQuarterRezColor = RenderTexture.GetTemporary (rtW4, rtH4, 0, rtFormat);
		Graphics.Blit (quarterRezColor, secondQuarterRezColor, screenBlend, 4 /* BloomTonedown */);

		if (BloomTrail) {
			if (oldBloom_ == null) {
				oldBloom_ = new RenderTexture (rtW4, rtH4, 0, rtFormat);
			}

			RenderTexture oldBloom2 = RenderTexture.GetTemporary (rtW4, rtH4, 0, rtFormat);
			Graphics.Blit (oldBloom_, oldBloom2);

			var alpha = Mathf.Pow (0.1f, Time.deltaTime);

			screenBlend.SetFloat ("_TrailAlpha", alpha);
			screenBlend.SetTexture ("_OldTex", oldBloom2);
			Graphics.Blit (secondQuarterRezColor, oldBloom_, screenBlend, 5 /* TrailBlend */);
			Graphics.Blit (oldBloom_, secondQuarterRezColor);
			RenderTexture.ReleaseTemporary (oldBloom2);
		}

		if (bloomBlurIterations < 1) bloomBlurIterations = 1;
		else if (bloomBlurIterations > 10) bloomBlurIterations = 10;

		for (int iter = 0; iter < bloomBlurIterations; iter++)
		{
			float spreadForPass = (1.0f + (iter * 0.25f)) * sepBlurSpread;

			// vertical blur
			RenderTexture blur4 = RenderTexture.GetTemporary (rtW4, rtH4, 0, rtFormat);
			screenBlend.SetVector ("_Offsets", new Vector4 (0.0f, spreadForPass * oneOverBaseSize, 0.0f, 0.0f));
			Graphics.Blit (secondQuarterRezColor, blur4, screenBlend, 2 /* blur */);
			RenderTexture.ReleaseTemporary(secondQuarterRezColor);
			secondQuarterRezColor = blur4;

			// horizontal blur
			blur4 = RenderTexture.GetTemporary (rtW4, rtH4, 0, rtFormat);
			screenBlend.SetVector ("_Offsets", new Vector4 ((spreadForPass / widthOverHeight) * oneOverBaseSize, 0.0f, 0.0f, 0.0f));
			Graphics.Blit (secondQuarterRezColor, blur4, screenBlend, 2 /* blur */);
			RenderTexture.ReleaseTemporary (secondQuarterRezColor);
			secondQuarterRezColor = blur4;
		}

		// 最終ブレンド
		screenBlend.SetFloat ("_Intensity", bloomIntensity);
		Graphics.Blit(secondQuarterRezColor, destination, screenBlend, 3 /* add */);

		RenderTexture.ReleaseTemporary (quarterRezColor);
		RenderTexture.ReleaseTemporary (secondQuarterRezColor);

	}

	public void OnRenderImage (RenderTexture source, RenderTexture destination)
	{
		if (CheckResources()==false)
		{
			Graphics.Blit (source, destination);
			return;
		}

		Graphics.Blit (source, destination, tonemapMaterial, 1 /* Tonemap */);

		if (BloomEnable) {
			BloomEffect (source, destination);
		}

	}

}
