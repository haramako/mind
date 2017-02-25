using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class TestScene : MonoBehaviour {

	public GradationTexture Grad;
	public Image Img;
	public Material Mat;
	public Material Mat2;
	public ToneMapImageEffect Effect;

	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		Mat.SetTexture ("_HPowerTex", Grad.Texture);
		Mat2.SetTexture ("_HPowerTex", Grad.Texture);
		var pow = 10 + 2 * Mathf.Sin (Time.time * 12);
		Effect.bloomIntensity = pow;
	}
}
