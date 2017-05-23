#include "UnityCG.cginc"

#ifndef SHADER_API_HAIR
#define SHADER_API_HAIR

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


float3 GetTriangleCenter(appdata_hair_gs _input[3]) {
	return (_input[0].position + _input[1].position + _input[2].position) / 3;
}

void BuildSprite(float3 position, float width, float height, inout TriangleStream<v2f> triangleStream) {
	float halfLocalWidth = width * 0.5f;
	float halfLocalHeight = height * 0.5f;

	// Add four vertices to the output stream that will be drawn as a triangle strip making a quad
	v2f fragmentData = BuildFragmentShaderData(float3(-halfLocalWidth, -halfLocalHeight, 0), position, float2(0, 0));
	triangleStream.Append(fragmentData);

	fragmentData = BuildFragmentShaderData(float3(halfLocalWidth, -halfLocalHeight, 0), position, float2(1, 0));
	triangleStream.Append(fragmentData);

	fragmentData = BuildFragmentShaderData(float3(-halfLocalWidth, halfLocalHeight, 0), position, float2(0, 1));
	triangleStream.Append(fragmentData);

	fragmentData = BuildFragmentShaderData(float3(halfLocalWidth, halfLocalHeight, 0), position, float2(1, 1));
	triangleStream.Append(fragmentData);
	triangleStream.RestartStrip();
}



#endif