using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Polychrome : MonoBehaviour {

	public GradationTexture2 Ambient;
	public Camera LightCamera;

	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		if (Application.isPlaying) {
			if (Ambient != null) {
				Ambient.Apply ();
			}
		} else {
			if (LightCamera != null) {
				Shader.SetGlobalTexture ("_LightTex", LightCamera.targetTexture);
			}
		}
	}

	void OnPreRender(){
		if (LightCamera != null) {
			Shader.SetGlobalTexture ("_LightTex", LightCamera.targetTexture);
		}
	}
}
