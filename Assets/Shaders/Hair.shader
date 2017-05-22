Shader "Custom/Hair" {
	Properties{
		_MainTex("Texture", 2D) = "white" {}
		_Colour("Colour", Color) = (0,0,0,1)
		Length("Length",Range(0.001,1)) = 0.04
		Width("Width",Range(0.001,1)) = 0.02
	}

	SubShader{
		Tags{ "RenderType" = "Opaque" }
		LOD 100
		Cull off
		Blend off

		Pass{
			CGPROGRAM

			//	Using geometry shader so target 4.0
			//	https://docs.unity3d.com/Manual/SL-ShaderCompileTargets.html
			#pragma target 4.0

			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geom

			#include "UnityCG.cginc"

			// Vertex Shader input structure
			struct appdata_hair_vs {
				float4 position : POSITION;
				float2 uv : TEXCOORD0;
			};

			// Geometry Shader input structure
			struct appdata_hair_gs {
				float4 position : POSITION;
			};

			// Fragment Shader input structure
			struct v2f {
				float4 screenPosition : SV_POSITION;
				float2 uv : TEXCOORD0;
			};


			sampler2D _MainTex;
			float Length;
			float Width;
			float4 _Colour;

			appdata_hair_gs BuildGeometryShaderData(float4 position) {
				appdata_hair_gs geometryShaderData = (appdata_hair_gs)0;
				float3 worldPos = mul(unity_ObjectToWorld, position);
				geometryShaderData.position = float4(worldPos, 1);
				return geometryShaderData;
			}


			v2f BuildFragmentShaderData(float3 offset, float3 position, float2 uv) {
				v2f fragmentData = (v2f)0;
				
				float3 worldPos = mul(UNITY_MATRIX_V, float4(position, 1)) + offset;
				fragmentData.screenPosition = mul(UNITY_MATRIX_P, float4(worldPos, 1));
				fragmentData.uv = uv;
				return fragmentData;
			}

			appdata_hair_gs vert(appdata_hair_vs hairVertex) {
				return BuildGeometryShaderData(hairVertex.position);
			}

			void BuildSprite(appdata_hair_gs hairVertex, inout TriangleStream<v2f> triangleStream) {
				float halfLocalWidth = Width * 0.5f;
				float halfLocalHeight = Length * 0.5f;

				// Add four vertices to the output stream that will be drawn as a triangle strip making a quad
				v2f fragmentData = BuildFragmentShaderData(float3(-halfLocalWidth, -halfLocalHeight, 0), hairVertex.position, float2(0, 0));
				triangleStream.Append(fragmentData);

				fragmentData = BuildFragmentShaderData(float3(halfLocalWidth, -halfLocalHeight, 0), hairVertex.position, float2(1, 0));
				triangleStream.Append(fragmentData);

				fragmentData = BuildFragmentShaderData(float3(-halfLocalWidth, halfLocalHeight, 0), hairVertex.position, float2(0, 1));
				triangleStream.Append(fragmentData);

				fragmentData = BuildFragmentShaderData(float3(halfLocalWidth, halfLocalHeight, 0), hairVertex.position, float2(1, 1));
				triangleStream.Append(fragmentData);
				triangleStream.RestartStrip();
			}

			[maxvertexcount(4)]
			void geom(point appdata_hair_gs _input[1], inout TriangleStream<v2f> triangleStream) {
				appdata_hair_gs hairVertex = _input[0];
				BuildSprite(hairVertex, triangleStream);
			}

			fixed4 frag(v2f i) : SV_Target{
				// sample the texture
				//return tex2D(_MainTex, i.uv);
				return _Colour;
			}
			ENDCG
		}
	}
}