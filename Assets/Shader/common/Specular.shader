Shader "Shao/Specular"
{
	Properties
	{
		_Color ("Diffuse", Color) = (1, 1, 1, 1)
		_MainTex ("Texture", 2D) = "white" {}
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Specular Gloss", Range(1, 256)) = 20
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}

		Pass
		{
			Tags { "LightMode"="ForwardBase"}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			#pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float3 worldNormal : TEXCOORD2;
				SHADOW_COORDS(3)
				UNITY_FOG_COORDS(4)

			};

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Specular;
			float _Gloss;
			
			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);

			#ifdef LIGHTMAP_ON
				o.uv.zw = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
			#endif

				TRANSFER_SHADOW(o);

				UNITY_TRANSFER_FOG(o,o.pos);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 texColor = tex2D(_MainTex, i.uv.xy);
				fixed3 albedo = texColor.rgb * _Color.rgb;

				fixed4 final;
			#ifdef LIGHTMAP_ON
				fixed3 lm = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv.zw));
				UNITY_LIGHT_ATTENUATION(atten, i, worldPos);
				final = fixed4(albedo * lm, 1);
			#else
				fixed3 N = normalize(i.worldNormal);
				fixed3 L = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 V = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 H = normalize(L + V);

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;
				fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(N, L));
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(N, H)), _Gloss);

				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

				final = fixed4(ambient + (diffuse + specular) * atten, 1);
			#endif

				UNITY_APPLY_FOG(i.fogCoord, final);

				return final;

			}
			ENDCG
		}
	}

	Fallback "Specular"
}
