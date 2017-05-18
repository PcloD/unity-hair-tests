Shader "Custom/Hair" {
	Properties{
		_MainTex("Texture", 2D) = "white" {}
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

#pragma shader_feature POINT_TOPOLOGY
#define GEOMETRY_TRIANGULATION

#ifndef GEOMETRY_TRIANGULATION
#define VERTEX_TRIANGULATION
#endif

#pragma vertex vert
#pragma fragment frag

#ifdef GEOMETRY_TRIANGULATION
#pragma geometry geom
#endif

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

#ifdef GEOMETRY_TRIANGULATION
			appdata_hair_gs vert(appdata_hair_vs hairVertex) {
				return BuildGeometryShaderData(hairVertex.position);
			}
#endif

#ifdef VERTEX_TRIANGULATION
			v2f vert(appdata_hair_vs hairVertex) {
				float3 objectPos = mul(unity_ObjectToWorld, hairVertex.position);
				return BuildFragmentShaderData(float3(0,0,0), objectPos, hairVertex.uv);
			}
#endif

#ifdef GEOMETRY_TRIANGULATION
#if POINT_TOPOLOGY
			[maxvertexcount(4)]
			void geom(point appdata_hair_gs _input[1], inout TriangleStream<v2f> triangleStream) {
				int index = 0;
#else
			[maxvertexcount(4)]
			void geom(triangle appdata_hair_gs _input[3], inout TriangleStream<v2f> triangleStream) {
				//	non-shared vertex in triangles is 2nd
				int index = 1;
#endif
				appdata_hair_gs hairVertex = _input[index];

				float halfLocalWidth = Width * 0.5f;
				float halfLocalHeight = Length * 0.5f;

				// Add four vertices to the output stream that will be drawn as a triangle strip making a quad
				v2f fragmentData = BuildFragmentShaderData(float3(-halfLocalWidth,-halfLocalHeight,0), hairVertex.position, float2(0,0));
				triangleStream.Append(fragmentData);

				fragmentData = BuildFragmentShaderData(float3(halfLocalWidth,-halfLocalHeight,0), hairVertex.position, float2(1, 0));
				triangleStream.Append(fragmentData);

				fragmentData = BuildFragmentShaderData(float3(-halfLocalWidth, halfLocalHeight,0), hairVertex.position, float2(0, 1));
				triangleStream.Append(fragmentData);

				fragmentData = BuildFragmentShaderData(float3(halfLocalWidth, halfLocalHeight, 0), hairVertex.position, float2(1, 1));
				triangleStream.Append(fragmentData);
			}
#endif//GEOMETRY_TRIANGULATION

			fixed4 frag(v2f i) : SV_Target{
				// sample the texture
				return tex2D(_MainTex, i.uv);
			}
			ENDCG
		}
	}
}