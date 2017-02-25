﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class GradationTexture : MonoBehaviour {

	public Texture2D Texture;
	public AnimationCurve HPowerCurve;
	public float Rotation;
	const int Resolution = 256;

	void Awake () {
		Texture = new Texture2D (Resolution, 1, TextureFormat.Alpha8, false);
		Texture.wrapMode = TextureWrapMode.Repeat;
		Texture.filterMode = FilterMode.Bilinear;
	}

	void Validate(){
		refresh ();
	}

	void refresh(){
		var data = new byte[Resolution];
		const float len = Resolution / 6f;
		for (int i = 0; i < Resolution; i++) {
			//var pos = (1f + Mathf.Abs (Mathf.Repeat (Time.time, 1f) - 0.5f) / 7f) * i; // ちょっと時間で色がずれるバージョン
			var pos = i;
			var pow = HPowerCurve.Evaluate (Mathf.Repeat (1f * pos / Resolution + Rotation, 1));
			data [i] = (byte)(Mathf.Clamp01(pow) * 255);
		}
		Texture.LoadRawTextureData (data);	
		Texture.Apply ();
	}
	
	void Update () {
		refresh ();
	}
}
