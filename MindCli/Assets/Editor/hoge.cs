using UnityEngine;
using UnityEditor;
using System.Collections;

public class Hoge : MonoBehaviour {
	static public void hoge(){
		var foo = AssetImporter.GetAtPath("hoge") as TextureImporter;

	}
}
