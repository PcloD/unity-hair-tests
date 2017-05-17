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

			struct appdata_hair {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f {
				float4 screenPos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};


			sampler2D _MainTex;
			float Length;
			float Width;

			v2f MakeFragmentData(float3 offset, float3 vertex, float2 uv) {
				v2f fragmentData = (v2f)0;

				float3 worldPos = mul(UNITY_MATRIX_V, float4(vertex,1)) + offset;
				fragmentData.screenPos = mul(UNITY_MATRIX_P, float4(worldPos, 1));
				fragmentData.uv = uv;
				return fragmentData;
			}

#ifdef GEOMETRY_TRIANGULATION
			v2f vert(appdata_hair hairData) {
				v2f fragmentData;

				fragmentData.screenPos = mul(unity_ObjectToWorld, hairData.vertex);
				fragmentData.uv = hairData.uv;

				return fragmentData;
			}
#endif

#ifdef VERTEX_TRIANGULATION
			v2f vert(appdata_hair hairData) {
				float4 localPos = hairData.vertex;
				float3 worldPos = mul(unity_ObjectToWorld, localPos);

				return MakeFragmentData(hairData.normal, worldPos, hairData.uv);
			}
#endif

#ifdef GEOMETRY_TRIANGULATION
#if POINT_TOPOLOGY
			[maxvertexcount(9)]
			void geom(point appdata_hair _input[1], inout TriangleStream<v2f> OutputStream) {
				int index = 0;
#else
			[maxvertexcount(9)]
			void geom(triangle appdata_hair _input[3], inout TriangleStream<v2f> OutputStream) {
				//	non-shared vertex in triangles is 2nd
				int index = 1;
#endif
				appdata_hair input = _input[index];

				float halfLocalWidth = Width * 0.5f;
				float halfLocalHeight = Length * 0.5f;

				// Add four vertices to the output stream that will be drawn as a triangle strip making a quad
				v2f fragmentData = MakeFragmentData(float3(-halfLocalWidth,-halfLocalHeight,0), input.vertex, input.uv);
				OutputStream.Append(fragmentData);

				fragmentData = MakeFragmentData(float3(halfLocalWidth,-halfLocalHeight,0), input.vertex, input.uv);
				OutputStream.Append(fragmentData);

				fragmentData = MakeFragmentData(float3(-halfLocalWidth, halfLocalHeight,0), input.vertex, input.uv);
				OutputStream.Append(fragmentData);

				fragmentData = MakeFragmentData(float3(halfLocalWidth, halfLocalHeight, 0), input.vertex, input.uv);
				OutputStream.Append(fragmentData);

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