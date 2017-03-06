using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Polychrome : MonoBehaviour {

	public GradationTexture2 Ambient;
	public Camera LightCamera;

	void Update () {
		if (Application.isPlaying) {
			if (Ambient != null) {
				Ambient.Apply ();
			}
		}

		if (LightCamera != null) {
			Shader.SetGlobalTexture ("_LightTex", LightCamera.targetTexture);
		}
	}

}
