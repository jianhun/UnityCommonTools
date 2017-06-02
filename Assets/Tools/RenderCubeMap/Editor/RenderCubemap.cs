using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class RenderCubemap : EditorWindow
{
	Transform renderFromPos;
	Cubemap cubemap;

	[MenuItem ("Tools/RenderCubemap")]
	static void AddWindow ()
	{
		RenderCubemap window = EditorWindow.GetWindow<RenderCubemap> (true, "立方体纹理");
		window.Show ();
	}

	void OnGUI ()
	{
		EditorGUIUtility.labelWidth = 80;

		renderFromPos = (Transform)EditorGUILayout.ObjectField ("位置", renderFromPos, typeof(Transform), true);

		EditorGUILayout.BeginHorizontal ();
		cubemap = (Cubemap)EditorGUILayout.ObjectField ("纹理", cubemap, typeof(Cubemap), false);
		GUILayout.FlexibleSpace ();
		EditorGUILayout.EndHorizontal ();

		if (GUILayout.Button ("渲染", GUILayout.Width (200))) {
			DoRender ();
		}
	}

	void DoRender ()
	{
		if (renderFromPos == null || cubemap == null)
			return;

		GameObject go = new GameObject ();
		go.AddComponent<Camera> ();
		go.transform.position = renderFromPos.position;
		go.GetComponent<Camera> ().RenderToCubemap (cubemap);
		DestroyImmediate (go);
	}
}
