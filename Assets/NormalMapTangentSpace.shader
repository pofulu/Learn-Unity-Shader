// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "UnityShaderBook/Chapter7/NormalMapInTangentSpace"
{
	Properties
	{
		_Color("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex("Main Tex", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1.0
		_Specular("Specular", Color) = (1, 1, 1, 1)
		_Gloss("Gloss", Range(8.0, 256)) = 20
	}
	
	SubShader
	{
		Pass
		{
			Tags {"LightMode" = "ForwardBase"}
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
				
			#include "Lighting.cginc"
				
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpScale;
			fixed4 _Specular;
			float _Gloss;
			
			struct a2v
			{
				float4 vertex : POSITION;
				float3 noraml : NORMAL;
				float4 trangent : TANGENT;
				float4 texcoord : TEXCOORD0; //Unity 會將模型的第一組紋理存到該變數中
			};
			
			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float3 lightDir : TEXCOORD1;
				float3 viewDir : TEXCOORD2;
			};
			
			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
				
				o.lightDir = mul(TANGENT_SPACE_ROTATION, ObjSpaceLightDir(v.vertex)).xyz;
				o.viewDir = mul(TANGENT_SPACE_ROTATION, ObjSpaceViewDir(v.vertex)).xyz;
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target //fixed4 因為片元著色器算出片元的顏色
			{
				fixed3 tangentLightDir = normalize(i.ligthDir); // 用於計算漫反射，漫反射需要 l(指向光源方向)
				fixed3 tangentViewDir = normalize(i.viewDir); // 用於計算高光反射，高光反射需要 r(指向反射方向) 跟 **v** (指向視角方向)
				
				// 計算漫反射跟高光反射都會用到 Normal
				fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
				fixed3 tangentNormal; // 計算切線空間下的 Normal
				
				// 計算漫反射
				tangentNormal = UnpackNormal(packedNormal);
				tangentNormal.xy *= _BumpScale;
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
				
				fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));
				
				// 計算高光反射
				fixed3 halfDir = normalize(tangentLightDir + tangentViewDir); // h是Blinn-Phong光照的向量，Blinn-Phong光照沒有使用反射方向r
				fixed3 specular = _LightColor0.rgb * _SpecColor.rgb * pow(max(0, dot(tangetNormal, halfDir)), _Gloss);
				
				return fixed4(ambient + diffuse + specular);
			}
			
			ENDCG
		}
	}
}
