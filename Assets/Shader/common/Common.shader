Shader "Shao/Common"
{
	Properties {
		_Color("Diffuser Color", Color) = (1, 1, 1, 1)
		_MainTex("MainTex", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
		_Specular("Specular Color", Color) = (1, 1, 1, 1)
		_Gloss("Specualr Gloss", Range(1, 256)) = 20
	}

	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}

		Pass {
			Tags {"LightMode"="ForwardBase"}

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
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			#ifdef LIGHTMAP_ON
				float4 texcoord1 : TEXCOORD1;
			#endif
			};

			struct v2f {
				float4 pos : SV_POSITION;
				half4 uv : TEXCOORD0;
				float4 TtoW0 : TEXCOORD1;
				float4 TtoW1 : TEXCOORD2;
				float4 TtoW2 : TEXCOORD3;
				SHADOW_COORDS(4)
				UNITY_FOG_COORDS(5)
			#ifdef LIGHTMAP_ON
				half4 uv2 : TEXCOORD6;
			#endif
			};

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			fixed4 _Specular;
			float _Gloss;

			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);
			#ifdef LIGHTMAP_ON
				o.uv2.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
			#endif

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldNormal = UnityObjectToWorldNormal(v.normal); 
				float3 worldTangent = UnityObjectToWorldDir(v.tangent);
				float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				TRANSFER_SHADOW(o)
				UNITY_TRANSFER_FOG(o, o.pos);

				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 texColor = tex2D(_MainTex, i.uv.xy);
				fixed3 albedo = texColor.rgb * _Color.rgb;

				fixed4 finalCol;
			#ifdef LIGHTMAP_ON
				fixed3 lm = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv2.xy));
				UNITY_LIGHT_ATTENUATION(atten, i, worldPos);
				finalCol = fixed4(albedo * lm, 1);
			#else
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
				fixed3 N = normalize(float3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				fixed3 L = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 V = normalize(UnityWorldSpaceViewDir(worldPos));
				fixed3 H = normalize(L + V);

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;
				fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(N, L));
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(N, H)), _Gloss);

				UNITY_LIGHT_ATTENUATION(atten, i, worldPos)
				finalCol = fixed4(ambient + (diffuse + specular) * atten, 1);

				// 4 point light
				// 放在vert里比较效率
//				#ifdef VERTEXLIGHT_ON
//				float3 pointLights = Shade4PointLights(
//					unity_4LightPosX0,
//				 	unity_4LightPosY0, 
//				 	unity_4LightPosZ0,
//				 	unity_LightColor[0].xyz, 
//				 	unity_LightColor[1].xyz,
//				 	unity_LightColor[2].xyz,
//				 	unity_LightColor[3].xyz,
//				 	unity_4LightAtten0,
//				 	worldPos,
//				 	N);
//				 finalCol.rgb += pointLights;
//				 #endif
				
			#endif

				UNITY_APPLY_FOG(i.fogCoord, finalCol);

				return finalCol;
			}

			ENDCG
		}

		Pass {
			Tags {"LightMode"="ForwardAdd"}

			Blend One One

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_fwdadd
			#pragma multi_compile_fog

			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				half4 uv : TEXCOORD0;
				float4 TtoW0 : TEXCOORD1;
				float4 TtoW1 : TEXCOORD2;
				float4 TtoW2 : TEXCOORD3;
				SHADOW_COORDS(4)
				UNITY_FOG_COORDS(5)
			};

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			fixed4 _Specular;
			float _Gloss;

			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldNormal = UnityObjectToWorldNormal(v.normal); 
				float3 worldTangent = UnityObjectToWorldDir(v.tangent);
				float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				TRANSFER_SHADOW(o)
				UNITY_TRANSFER_FOG(o, o.pos);

				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 texColor = tex2D(_MainTex, i.uv.xy);
				fixed3 albedo = texColor.rgb * _Color.rgb;

				fixed4 finalCol;

				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
				fixed3 N = normalize(float3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				fixed3 L = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 V = normalize(UnityWorldSpaceViewDir(worldPos));
				fixed3 H = normalize(L + V);

				fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(N, L));
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(N, H)), _Gloss);

				UNITY_LIGHT_ATTENUATION(atten, i, worldPos)
				finalCol = fixed4((diffuse + specular) * atten, 1);

				UNITY_APPLY_FOG_COLOR(i.fogCoord, finalCol, fixed4(0, 0, 0, 0));

				return finalCol;
			}

			ENDCG
		}
	}

	Fallback "Specular"
}
