using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using System.IO;

[ExecuteInEditMode]
public class TestScene : MonoBehaviour {

	public Polychrome Polychrome;
	public ToneMapImageEffect Effect;
	public Button[] ColorButtons;
	public GameObject MainCanvas;
	public PoolBehavior FileItemPool;
	public GameObject FileList;
	public Dropdown ImageType;

	public SpriteRenderer[] MainImages;

	string[] images = new string[3] { "", "", ""};

	int imageType;

	// Use this for initialization
	void Start () {
		if (Application.isPlaying) {
			for (int i = 0; i < images.Length; i++) {
				images [i] = ""+PlayerPrefs.GetString ("Image." + i);
			}

			reloadDir ();
			MainCanvas.SetActive (true);
			redraw ();
			redrawImage ();
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

	void reloadDir(){
		FileItemPool.ReleaseAll ();

		{
			var obj = FileItemPool.Create ();
			var item = obj.GetComponent<Text> ();
			item.text = "（なし）";
			obj.name = "FileItem:";
			obj.transform.SetParent (FileList.transform, false);
			obj.SetActive (true);
		}

		foreach (var file in Directory.GetFiles("Images", "*.png")) {
			var obj = FileItemPool.Create ();
			var item = obj.GetComponent<Text> ();
			item.text = file;
			obj.name = "FileItem:" + file;
			obj.transform.SetParent (FileList.transform, false);
			obj.SetActive (true);

		}
	}

	public void OnFileClick(GameObject target){
		var path = target.GetStringId ();
		Debug.Log (path);
		images [imageType] = path;
		redrawImage ();
	}

	public void redrawImage(){
		for (int i = 0; i < images.Length; i++) {
			var img = MainImages [i];
			if (images [i] == "") {
				img.sprite = null;
			} else {
				var tex = LoadPNG (images [i]);
				try {
					var sprite = Sprite.Create (tex, new Rect (0, 0, tex.width, tex.height), new Vector2 (0.5f, 0.5f));
					img.sprite = sprite;
				} catch (System.Exception ex) {
					Debug.LogException (ex);
				}
			}
			PlayerPrefs.SetString ("Image." + i, images [i]);
		}
		PlayerPrefs.Save ();
		Resources.UnloadUnusedAssets ();
	}

	// PNGファイルを読み込む
	public static Texture2D LoadPNG(string path) 
	{
		var s = File.OpenRead (path);
		using (var r = new BinaryReader (s)) {
			byte[] data = r.ReadBytes ((int)r.BaseStream.Length);

			int pos = 16; // 16バイトから開始

			int width = 0;
			for (int i = 0; i < 4; i++) {
				width = width * 256 + data [pos++];
			}

			int height = 0;
			for (int i = 0; i < 4; i++) {
				height = height * 256 + data [pos++];
			}

			Texture2D tex = new Texture2D (width, height, TextureFormat.ARGB32, false, true);
			tex.LoadImage (data);

			return tex;
		}
	}


	public void OnImageTypeChange(){
		imageType = ImageType.value;
	}

	public void OnReloadClick(){
		redrawImage ();
		reloadDir ();
	}

	public void OnHelpClick(){
		Application.OpenURL ("https://google.co.jp/");
	}
}
