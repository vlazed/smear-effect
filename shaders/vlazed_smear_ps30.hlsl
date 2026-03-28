// Defines cEyePos
#include "common_ps_fxc.h"

sampler BASETEXTURE : register(s0);

float4 COLOR : register(c0);
float4 BRIGHTNESS : register(c1);

struct PS_INPUT
{
    float2 uv : TEXCOORD0;             // Position on triangle
    float4 smearAlpha: COLOR0;
    float4 projPos : TEXCOORD6;
};

float ease_in_out_quint(float x) {
	float t = x; float b = 0; float c = 1; float d = 1;
	if ((t/=d/2) < 1) return c/2*t*t*t*t*t + b;
	return c/2*((t-=2)*t*t*t*t + 2) + b;
}

struct PS_OUTPUT
{
    float4 color0 : COLOR0;
    float depth0 : DEPTH0;
};

PS_OUTPUT main(PS_INPUT frag)
{
    // return float4(TRANSPARENCY.x, 0.0, 0.0, 1.0);
    float smearAlpha = ease_in_out_quint(clamp(length(frag.smearAlpha.xyz), 0, 1));

    PS_OUTPUT output = (PS_OUTPUT)0;
    float depth = frag.projPos.z / frag.projPos.w * smearAlpha;
    // output.color0 = float4(depth, depth, depth, 1);
    output.color0 = float4(BRIGHTNESS.x * COLOR.rgb * tex2D(BASETEXTURE, frag.uv).xyz, COLOR.a * smearAlpha);
    output.depth0 = depth;

    return output;
}