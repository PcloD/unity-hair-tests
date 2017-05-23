Shader "Custom/Hair2" {
	Properties{
		_TransparencyMask("Hair Transparency Mask", 2D) = "white" {}
		_Colour("Colour", Color) = (0,0,0,1)
		_Length("Length",Range(0.001,1)) = 0.04
		_Width("Width",Range(0.001,1)) = 0.02
	}

	SubShader{
		Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "True" }
		LOD 100
		Cull off
		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha // Traditional transparency

		Pass{
			CGPROGRAM

			//	Using geometry shader so target 4.0
			//	https://docs.unity3d.com/Manual/SL-ShaderCompileTargets.html
			#pragma target 4.0

			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geom

			#include "Hair.cginc"

			sampler2D _TransparencyMask;
			float _Length;
			float _Width;
			float4 _Colour;

			appdata_hair_gs vert(appdata_hair_vs hairVertex) {
				return BuildGeometryShaderData(hairVertex.position);
			}

			[maxvertexcount(16)]
			void geom(triangle appdata_hair_gs _input[3], inout TriangleStream<v2f> triangleStream) {
				float3 position = _input[0].position + ((_input[1].position -_input[0].position) * 0.5f);
				BuildSprite(position, _Width, _Length, triangleStream);

				position = _input[0].position + ((_input[2].position - _input[0].position) * 0.5f);
				BuildSprite(position, _Width, _Length, triangleStream);

				position = _input[1].position + ((_input[2].position - _input[1].position) * 0.5f);
				BuildSprite(position, _Width, _Length, triangleStream);

				position = GetTriangleCenter(_input);
				BuildSprite(position, _Width, _Length, triangleStream);
			}

			fixed4 frag(v2f i) : SV_Target{
				// sample the texture
				float4 transparencyMask = tex2D(_TransparencyMask, i.uv);
				float3 colour = _Colour.xyz;

				//return float4(colour.xyz * transparencyMask.xyz, transparencyMask.x);
				return float4(colour.xyz, transparencyMask.x);
			}
			ENDCG
		}
	}
}