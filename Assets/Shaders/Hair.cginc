#include "UnityCG.cginc"

#ifndef SHADER_API_HAIR
#define SHADER_API_HAIR

//#define ENABLE_ROTATION_ABOUT_DIRECTION
#define APPLY_TANGENT_ROTATION_TO_OFFSET

// Vertex Shader input structure
struct appdata_hair_vs {
	float4 position : POSITION;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float2 uv : TEXCOORD0;
};

// Geometry Shader input structure
struct appdata_hair_gs {
	float4 position : POSITION;
	float3 normal: NORMAL;
	float4 tangent : TANGENT;
};

// Fragment Shader input structure
struct v2f {
	float4 screenPosition : SV_POSITION;
	float2 uv : TEXCOORD0;
};


appdata_hair_gs BuildGeometryShaderData(float4 position, float3 normal, float4 tangent) {
	appdata_hair_gs geometryShaderData = (appdata_hair_gs)0;
	geometryShaderData.position = position;
	geometryShaderData.normal = normal;
	geometryShaderData.tangent = tangent;
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



v2f BuildFragmentShaderData(float3 vertexLocalPosition, float3 position, float3 direction, float2 uv) {
	v2f fragmentData = (v2f)0;

#if defined(ENABLE_ROTATION_ABOUT_DIRECTION)
	float3 vertexPos = vertexLocalPosition;
#else
	float3 vertexPos = position + vertexLocalPosition;
#endif
	float3 worldPos = mul(UNITY_MATRIX_V, float4(vertexPos, 1));

	fragmentData.screenPosition = mul(UNITY_MATRIX_P, float4(worldPos, 1));
	fragmentData.uv = uv;
	return fragmentData;
}


float3 GetTriangleCenter(appdata_hair_gs _input[3]) {
	return (_input[0].position + _input[1].position + _input[2].position) / 3;
}


void BuildSpriteVertex(float3 vertexLocalPosition, float3 position, float3 direction, float2 uv, inout TriangleStream<v2f> triangleStream) {
#if defined(ENABLE_ROTATION_ABOUT_DIRECTION)
	float3 newVertexLocalPosition = (direction.y < -0.99f ? vertexLocalPosition : RotatePointAboutDirectionVector(vertexLocalPosition, direction));
	newVertexLocalPosition = newVertexLocalPosition + position;
	newVertexLocalPosition = mul(unity_ObjectToWorld, float4(newVertexLocalPosition, 1));
#else
	float3 newVertexLocalPosition = vertexLocalPosition;
	position = mul(unity_ObjectToWorld, float4(position, 1));
#endif
	v2f fragmentData = BuildFragmentShaderData(newVertexLocalPosition, position, direction, uv);
	triangleStream.Append(fragmentData);
}


void BuildSprite(float3 position, float width, float height, float3 direction, float3 tangent, inout TriangleStream<v2f> triangleStream) {
	float halfLocalWidth = width * 0.5f;
	float yOffset = 0.001f;

#if defined(APPLY_TANGENT_ROTATION_TO_OFFSET)
	// Add four vertices to the output stream that will be drawn as a triangle strip making a quad
	BuildSpriteVertex(float3(-halfLocalWidth*tangent.x, yOffset, -halfLocalWidth*tangent.z), position, direction, float2(0, 1), triangleStream);
	BuildSpriteVertex(float3(halfLocalWidth*tangent.x, yOffset, halfLocalWidth*tangent.z), position, direction, float2(1, 1), triangleStream);
	BuildSpriteVertex(float3(-halfLocalWidth*tangent.x, -(height - yOffset), -halfLocalWidth*tangent.z), position, direction, float2(0, 0), triangleStream);
	BuildSpriteVertex(float3(halfLocalWidth*tangent.x, -(height - yOffset), halfLocalWidth*tangent.z), position, direction, float2(1, 0), triangleStream);
#else
	BuildSpriteVertex(float3(-halfLocalWidth, yOffset, 0), position, direction, float2(0, 1), triangleStream);
	BuildSpriteVertex(float3(halfLocalWidth, yOffset, 0), position, direction, float2(1, 1), triangleStream);
	BuildSpriteVertex(float3(-halfLocalWidth, -(height - yOffset), 0), position, direction, float2(0, 0), triangleStream);
	BuildSpriteVertex(float3(halfLocalWidth, -(height - yOffset), 0), position, direction, float2(1, 0), triangleStream);
#endif

}



#endif