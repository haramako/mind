using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[ExecuteInEditMode]
public class TestScene : MonoBehaviour {

	public Polychrome Polychrome;
	public Image Img;
	public Material Mat;
	public Material Mat2;
	public Material Mat3;
	public ToneMapImageEffect Effect;
	public Button[] ColorButtons;
	public GameObject MainCanvas;

	// Use this for initialization
	void Start () {
		if (Application.isPlaying) {
			MainCanvas.SetActive (true);
			redraw ();
		}
	}
	
	// Update is called once per frame
	void Update () {
		if (Application.isPlaying) {
			var pow = 10 + 2 * Mathf.Sin (Time.time * 12);
			Effect.bloomIntensity = pow;
		}
	}

	public void OnColorButtonClick(GameObject target){
		var id = target.GetId ();
		Polychrome.Ambient.CurveEnabled [id] = !Polychrome.Ambient.CurveEnabled [id];
		redraw ();
	}

	void redraw(){
		for (int i = 0; i < 5; i++) {
			var color = Polychrome.Ambient.CurveEnabled [i] ? Color.white : Color.gray;
			ColorButtons [i].GetComponent<Image> ().color = color;
		}
	}
}
