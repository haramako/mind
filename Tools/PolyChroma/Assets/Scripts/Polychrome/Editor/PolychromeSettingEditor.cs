using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using L = UnityEditor.EditorGUILayout;

public class PolychromeSetting : ScriptableObject {
	public GradationTexture2 Gradation;
	public bool[] Enabled = new bool[7];
}

public class PolychromeSettingEditor : EditorWindow {

	SerializedObject ser_;
	bool enabled_;
	PolychromeSetting setting_;
	SerializedProperty gradationProp_;

	void Awake(){
		if (ser_ == null) {
			setting_ = (PolychromeSetting)AssetDatabase.LoadAssetAtPath ("Assets/PolychromeSetting.asset", typeof(PolychromeSetting));
			if (setting_ == null) {
				Debug.Log ("Create PolychromeSetting");
				setting_ = ScriptableObject.CreateInstance<PolychromeSetting> ();
				AssetDatabase.CreateAsset (setting_, "Assets/PolychromeSetting.asset");
				AssetDatabase.Refresh ();
			}
			ser_ = new SerializedObject (setting_);
			gradationProp_ = ser_.FindProperty ("Gradation");
		}
	}
	
	void OnGUI(){
		Awake ();
		ser_.Update ();
		L.BeginVertical ();

		enabled_ = L.Toggle ("有効",enabled_);

		L.Separator ();

		L.ObjectField (gradationProp_, typeof(GradationTexture2));

		L.BeginHorizontal ();
		L.LabelField ("ライト", GUILayout.Width (60));
		for (int i = 0; i < setting_.Enabled.Length; i++) {
			setting_.Enabled [i] = L.Toggle (setting_.Enabled [i], GUILayout.Width (20));
		}
		L.EndHorizontal ();

		L.EndVertical ();

		ser_.ApplyModifiedProperties ();

		if (enabled_ && setting_.Gradation != null) {
			var grad = setting_.Gradation;
			for( int i= 0; i<grad.CurveEnabled.Length; i++){
				grad.CurveEnabled [i] = setting_.Enabled [i];
			}
			Shader.SetGlobalTexture ("_HPowerTex", setting_.Gradation.GetTexture ());
		}
	}

	[MenuItem("Window/Polychrome/Setting")]
	static void Open ()
	{
		GetWindow<PolychromeSettingEditor> ();
	}
}
