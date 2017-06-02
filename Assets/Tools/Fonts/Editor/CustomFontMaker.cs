using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Xml;
using System.IO;
using System.Text;

public class CustomFontMaker : EditorWindow
{
	public Texture2D texture;
	public TextAsset xmlAsset;

	public int lineHeight = 0;
	public bool isCopyNew = false;

	[MenuItem ("Tools/CustomFontMaker")]
	static void AddWindow ()
	{
		Rect r = new Rect (0, 0, 300, 300);
		CustomFontMaker window = (CustomFontMaker)EditorWindow.GetWindowWithRect<CustomFontMaker> (r, true, "自定义字体");
		window.Show ();
	}

	void OnGUI ()
	{
		EditorGUIUtility.labelWidth = 80;

		EditorGUILayout.BeginHorizontal ();
		texture = (Texture2D)EditorGUILayout.ObjectField ("字体贴图", texture, typeof(Texture2D), false);
		GUILayout.FlexibleSpace ();
		EditorGUILayout.EndHorizontal ();

		xmlAsset = (TextAsset)EditorGUILayout.ObjectField ("字体XML文件", xmlAsset, typeof(TextAsset), false);

		EditorGUILayout.Space ();

		isCopyNew = EditorGUILayout.ToggleLeft ("是否替换（如果字体正在使用，则谨慎选择）", isCopyNew);

		EditorGUILayout.BeginHorizontal ();
		GUILayout.FlexibleSpace ();
		if (GUILayout.Button ("创建字体", GUILayout.Width (200))) {
			this.CreateFont ();
		}
		GUILayout.FlexibleSpace ();
		EditorGUILayout.EndHorizontal ();

		EditorGUILayout.Space ();
		EditorGUILayout.LabelField ("自定义字体不支持脚本修改lineHeight，需要手动修改。");
		EditorGUILayout.LabelField ("lineHeight:" + lineHeight);
	}

	void CreateFont ()
	{
		if (texture == null) {
			return;
		}

		string texturePath = AssetDatabase.GetAssetPath (texture);
		string path = texturePath.Substring (0, texturePath.LastIndexOf ('.'));
		string matPath = path + ".mat";
		string fontPath = path + ".fontsettings";

		Material mat = AssetDatabase.LoadAssetAtPath<Material> (matPath);
		if (mat == null) {
			mat = new Material (Shader.Find ("GUI/Text Shader"));
			AssetDatabase.CreateAsset (mat, matPath);
		} else {
			mat.shader = Shader.Find ("GUI/Text Shader");
		}
		mat.SetTexture ("_MainTex", texture);

		Font font = AssetDatabase.LoadAssetAtPath<Font> (fontPath);
		if (font == null) {
			font = new Font ();
			AssetDatabase.CreateAsset (font, fontPath);
		}
		font.material = mat;

		if (xmlAsset) {
			UpdateFontByXml (font, xmlAsset);
		} else {
			UpdateFontByTexture (font, texture);
		}

		EditorUtility.SetDirty (mat);
		EditorUtility.SetDirty (font);

		AssetDatabase.SaveAssets ();
		AssetDatabase.Refresh ();

		if (isCopyNew)
			AssetDatabase.CopyAsset (AssetDatabase.GetAssetPath (font), AssetDatabase.GetAssetPath (font));
	}

	void  UpdateFontByTexture (Font f, Texture tex)
	{
		int count = 10;
		int width = tex.width;
		int height = tex.height;

		float _uvOffX = 1.0f / count;
		int charaWidth = width / count;
		int charaHeight = height;

		CharacterInfo[] _infos = new CharacterInfo[count];
		for (int i = 0; i < count; i++) {
			CharacterInfo _characterInfo = new CharacterInfo ();
			_characterInfo.index = 48 + i;

			_characterInfo.uvTopLeft = new Vector2 (i * _uvOffX, 1);
			_characterInfo.uvTopRight = new Vector2 (i * _uvOffX + _uvOffX, 1);
			_characterInfo.uvBottomLeft = new Vector2 (i * _uvOffX, 0);
			_characterInfo.uvBottomRight = new Vector2 (i * _uvOffX + _uvOffX, 0);

			_characterInfo.minX = 0;
			_characterInfo.minY = -charaHeight / 2;
			_characterInfo.maxX = _characterInfo.minX + charaWidth;
			_characterInfo.maxY = _characterInfo.minY + charaHeight;

			_characterInfo.advance = charaWidth;

			_infos [i] = _characterInfo;
		}

		f.characterInfo = _infos;

		lineHeight = charaHeight;
	}

	void UpdateFontByXml (Font f, TextAsset xml)
	{
		if (f == null || xml == null) {
			Debug.Log ("[CustomFontMaker] UpdateFontByXml : font or xml is null");
			return;
		}

		XmlDocument _doc = new XmlDocument ();
		byte[] _array = Encoding.ASCII.GetBytes (xml.text);
		MemoryStream _stream = new MemoryStream (_array);
		_doc.Load (_stream);

		XmlNode _font = _doc.SelectSingleNode ("font");
		XmlElement _common = (XmlElement)_font.SelectSingleNode ("common");

		int _lineHeight = int.Parse (_common.GetAttribute ("lineHeight"));
		float _scaleW = float.Parse (_common.GetAttribute ("scaleW"));
		float _scaleH = float.Parse (_common.GetAttribute ("scaleH"));

		XmlNode _chars = _font.SelectSingleNode ("chars");
		XmlNodeList _charsList = _chars.ChildNodes;

		CharacterInfo[] _infos = new CharacterInfo[_charsList.Count];

		for (int i = 0; i < _charsList.Count; i++) {
			XmlElement _element = (XmlElement)_charsList [i];
			CharacterInfo _characterInfo = new CharacterInfo ();
			_characterInfo.index = int.Parse (_element.GetAttribute ("id"));

			float _x = float.Parse (_element.GetAttribute ("x"));
			float _y = float.Parse (_element.GetAttribute ("y"));

			int _width = int.Parse (_element.GetAttribute ("width"));
			int _height = int.Parse (_element.GetAttribute ("height"));

			int _xoffset = int.Parse (_element.GetAttribute ("xoffset"));
			int _yoffset = int.Parse (_element.GetAttribute ("yoffset"));
			int _xadvance = int.Parse (_element.GetAttribute ("xadvance"));

			float uv_x = _x / _scaleW;
			float uv_y = 1 - _y / _scaleH;
			float uv_width = _width / _scaleW;
			float uv_height = _height / _scaleH;

			_characterInfo.uvTopLeft = new Vector2 (uv_x, uv_y);
			_characterInfo.uvTopRight = new Vector2 (uv_x + uv_width, uv_y);
			_characterInfo.uvBottomLeft = new Vector2 (uv_x, uv_y - uv_height);
			_characterInfo.uvBottomRight = new Vector2 (uv_x + uv_width, uv_y - uv_height);

			_characterInfo.minX = _xoffset;
			_characterInfo.minY = -_yoffset - _height / 2;
			_characterInfo.maxX = _characterInfo.minX + _width;
			_characterInfo.maxY = _characterInfo.minY + _height;

			_characterInfo.advance = _xadvance;

			_infos [i] = _characterInfo;
		}

		f.characterInfo = _infos;

		lineHeight = _lineHeight;
	}
}
