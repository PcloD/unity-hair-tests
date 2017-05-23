// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

#include "UnityCG.cginc"

#ifndef SHADER_API_HAIR
#define SHADER_API_HAIR

// Vertex Shader input structure
struct appdata_hair_vs {
	float4 position : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
};

// Geometry Shader input structure
struct appdata_hair_gs {
	float4 position : POSITION;
	float3 normal: NORMAL;
};

// Fragment Shader input structure
struct v2f {
	float4 screenPosition : SV_POSITION;
	float2 uv : TEXCOORD0;
};


appdata_hair_gs BuildGeometryShaderData(float4 position, float3 normal) {
	appdata_hair_gs geometryShaderData = (appdata_hair_gs)0;
	float3 worldPos = mul(unity_ObjectToWorld, position);
	geometryShaderData.position = float4(worldPos, 1);
	geometryShaderData.normal = normal;
	return geometryShaderData;
}


float3x3 BuildRotationMatrixFromDirectionVector(float3 direction) {
	float3 up = float3(0, 1, 0);

	float3 v = cross(up, direction);
	float s = length(v);  // Sine of the angle
	float c = dot(up, direction); // Cosine of the angle
	float3x3 VX = float3x3 (
		0, -1 * v.z, v.y,
		v.z, 0, -1 * v.x,
		-1 * v.y, v.x, 0
		); // This is the skew-symmetric cross-product matrix of v
	float3x3 I = float3x3 (
		1, 0, 0,
		0, 1, 0,
		0, 0, 1
		); // The identity matrix
	return (I + VX + mul(VX, VX) * (1 - c) / pow(s, 2));
}

float3 RotatePointAboutDirectionVector(float3 position, float3 direction) {
	float3x3 rotation = BuildRotationMatrixFromDirectionVector(direction);
	return mul(rotation, position);
}



v2f BuildFragmentShaderData(float3 offset, float3 position, float2 uv) {
	v2f fragmentData = (v2f)0;

	float3 worldPos = mul(UNITY_MATRIX_V, float4(position + offset, 1));
	fragmentData.screenPosition = mul(UNITY_MATRIX_P, float4(worldPos, 1));
	fragmentData.uv = uv;
	return fragmentData;
}


float3 GetTriangleCenter(appdata_hair_gs _input[3]) {
	return (_input[0].position + _input[1].position + _input[2].position) / 3;
}

void BuildSprite(float3 position, float width, float height, float3 direction, inout TriangleStream<v2f> triangleStream) {
	float halfLocalWidth = width * 0.5f;

	// Add four vertices to the output stream that will be drawn as a triangle strip making a quad
	float3 offset = RotatePointAboutDirectionVector(float3(-halfLocalWidth, 0, 0), direction);
	v2f fragmentData = BuildFragmentShaderData(offset, position, float2(0, 1));
	triangleStream.Append(fragmentData);

	offset = RotatePointAboutDirectionVector(float3(halfLocalWidth, 0, 0), direction);
	fragmentData = BuildFragmentShaderData(offset, position, float2(1, 1));
	triangleStream.Append(fragmentData);

	offset = RotatePointAboutDirectionVector(float3(-halfLocalWidth, height, 0), direction);
	fragmentData = BuildFragmentShaderData(offset, position, float2(0, 0));
	triangleStream.Append(fragmentData);

	offset = RotatePointAboutDirectionVector(float3(halfLocalWidth, height, 0), direction);
	fragmentData = BuildFragmentShaderData(offset, position, float2(1, 0));
	triangleStream.Append(fragmentData);
	triangleStream.RestartStrip();
}



#endif