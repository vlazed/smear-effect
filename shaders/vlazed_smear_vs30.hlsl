//	DYNAMIC: "SKINNING"					"0..1"

// Smear effect is ported from https://github.com/cjacobwade/HelpfulScripts/blob/de0133e0c33a8b80501945a0253ba061f18a034b/SmearEffect/Smear.shader

#include "common_vs_fxc.h"

static const bool g_bSkinning		= SKINNING ? true : false;

// Our default vertex data input structure
struct VS_INPUT
{
	// This is all of the stuff that we ever use.
	float4 vPos				: POSITION;
	float4 vBoneWeights		: BLENDWEIGHT;
	float4 vBoneIndices		: BLENDINDICES;
	float4 vNormal			: NORMAL;
	float4 vColor			: COLOR0;
	float3 vSpecular		: COLOR1;
	// make these float2's and stick the [n n 0 1] in the dot math.
	float4 vTexCoord0		: TEXCOORD0;
	float4 vTexCoord1		: TEXCOORD1;
	float4 vTexCoord2		: TEXCOORD2;
	float4 vTexCoord3		: TEXCOORD3;
	float3 vTangentS		: TANGENT;
	float3 vTangentT		: BINORMAL;
	float4 vUserData		: TANGENT;

	// Position and normal/tangent deltas
	float3 vPosFlex			: POSITION1;
	float3 vNormalFlex		: NORMAL1;
#ifdef SHADER_MODEL_VS_3_0
	float vVertexID			: POSITION2;
#endif
};

float hash3(float n)
{
	return frac(sin(n)*43758.5453);
}

float noise(float3 x)
{
	// The noise function returns a value in the range -1.0f -> 1.0f

	float3 p = floor(x);
	float3 f = frac(x);

	f = f*f*(3.0 - 2.0*f);
	float n = p.x + p.y*57.0 + 113.0*p.z;

	return lerp(lerp(lerp(hash3(n + 0.0), hash3(n + 1.0), f.x),
		lerp(hash3(n + 57.0), hash3(n + 58.0), f.x), f.y),
		lerp(lerp(hash3(n + 113.0), hash3(n + 114.0), f.x),
			lerp(hash3(n + 170.0), hash3(n + 171.0), f.x), f.y), f.z);
}

struct VS_OUTPUT
{
	// Stuff that isn't seen by the pixel shader
	float4 projPos: POSITION;
#if !defined( _X360 )
	float  fog													: FOG;
#endif
	// Stuff that is seen by the pixel shader

	float2 uv			: TEXCOORD0;
	float3 lightAtten											: TEXCOORD1;
	float4 worldVertToEyeVectorXYZ_tangentSpaceVertToEyeVectorZ	: TEXCOORD2;
	float3 vWorldNormal											: TEXCOORD3;	// World-space normal
	float4 vWorldTangent										: TEXCOORD4;
#if	USE_WITH_2B
	float4 vProjPos												: TEXCOORD5;
#else
	float3 vWorldBinormal										: TEXCOORD5;
#endif
	float4 smearAlpha											: COLOR0;

#if defined( _X360 ) && FLASHLIGHT
	float4 flashlightSpacePos									: TEXCOORD8;
#endif
};

float hash2(float x) {
	return sin(x * 5.0);
}

// The code below runs for every vertex in the model
VS_OUTPUT main(VS_INPUT v)
{
	// All of this is copied from vertexlit_and_unlit_generic_bump_vs20.fxc
	// https://github.com/ValveSoftware/source-sdk-2013/blob/38fd28f96c13232b313a3e20e528becd33efc41e/src/materialsystem/stdshaders/vertexlit_and_unlit_generic_bump_vs20.fxc#L105
	float4 vPosition = v.vPos;
	float3 vNormal;
	float4 vTangent;
	DecompressVertex_NormalTangent( v.vNormal, v.vUserData, vNormal, vTangent );

#if !defined( SHADER_MODEL_VS_3_0 ) || !MORPHING
	ApplyMorph( v.vPosFlex, v.vNormalFlex, vPosition.xyz, vNormal, vTangent.xyz );
#else
	ApplyMorph( morphSampler, cMorphTargetTextureDim, cMorphSubrect, 
		v.vVertexID, v.vTexCoord2, vPosition.xyz, vNormal, vTangent.xyz );
#endif

	// Perform skinning
	float3 worldNormal, worldPos, worldTangentS, worldTangentT;
	SkinPositionNormalAndTangentSpace( g_bSkinning, vPosition, vNormal, vTangent,
		v.vBoneWeights, v.vBoneIndices, worldPos,
		worldNormal, worldTangentS, worldTangentT );

	// Always normalize since flex path is controlled by runtime
	// constant not a shader combo and will always generate the normalization
	worldNormal   = normalize( worldNormal );
	worldTangentS = normalize( worldTangentS );
	worldTangentT = normalize( worldTangentT );

#if defined( SHADER_MODEL_VS_3_0 ) && MORPHING && DECAL
	// Avoid z precision errors
	worldPos += worldNormal * 0.05f * v.vTexCoord2.z;
#endif

	// Smearing from https://github.com/cjacobwade/HelpfulScripts/blob/de0133e0c33a8b80501945a0253ba061f18a034b/SmearEffect/Smear.shader
	float3 position = float3(cAmbientCubeX[0].x, cAmbientCubeX[0].y, cAmbientCubeX[0].z);
	float3 prevPosition = float3(cAmbientCubeX[1].x, cAmbientCubeX[1].y, cAmbientCubeX[1].z);
	float noiseScale = cAmbientCubeY[0].x;
	float noiseHeight = cAmbientCubeY[0].y;
	float curTime = cAmbientCubeY[0].z;

	float3 worldOffset = position.xyz - prevPosition.xyz; // -5
	float3 localOffset = worldPos.xyz - position.xyz; // -5

	// World offset should only be behind swing
	float dirDot = dot(normalize(worldOffset), normalize(localOffset));
	float3 unitVec = float3(1, 1, 1) * noiseHeight;
	worldOffset = clamp(worldOffset, unitVec * -1, unitVec);
	worldOffset *= -clamp(dirDot, -1, 0) * lerp(1, 0, step(length(worldOffset), 0));

	float3 smearOffset = -worldOffset.xyz * lerp(1, noise(worldPos * noiseScale), step(0, noiseScale));
	worldPos.xyz += smearOffset;
	// worldPos.xyz += hash2(curTime);

	VS_OUTPUT output = (VS_OUTPUT)0;
	output.vWorldNormal.xyz = worldNormal.xyz;
	output.vWorldTangent = float4( worldTangentS.xyz, vTangent.w );	 // Propagate binormal sign in world tangent.w
	// Smear alpha to pass to pixel shader
	output.smearAlpha = float4(worldOffset, 0.0);

	// Transform into projection space
	float4 vProjPos = mul( float4( worldPos, 1 ), cViewProj );
	output.projPos = vProjPos;
	output.uv = v.vTexCoord0.xy;

	return output;
};