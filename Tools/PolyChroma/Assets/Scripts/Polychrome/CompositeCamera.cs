using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class CompositeCamera : MonoBehaviour {

	public Camera FarCamera;
	public Camera NearCamera;
	public Camera LightCamera;

	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		FarCamera.aspect = 1f * Screen.width / Screen.height;
		NearCamera.aspect = 1f * Screen.width / Screen.height;
		LightCamera.aspect = 1f * Screen.width / Screen.height;
	}
}
