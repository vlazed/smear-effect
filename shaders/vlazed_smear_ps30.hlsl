// Defines cEyePos
#include "common_ps_fxc.h"

sampler BASETEXTURE : register(s0);

float4 COLOR : register(c0);
float4 BRIGHTNESS : register(c1);

struct PS_INPUT
{
    float2 uv : TEXCOORD0;             // Position on triangle
    float4 smearAlpha: COLOR0;
};

float ease_in_out_quint(float x) {
	float t = x; float b = 0; float c = 1; float d = 1;
	if ((t/=d/2) < 1) return c/2*t*t*t*t*t + b;
	return c/2*((t-=2)*t*t*t*t + 2) + b;
}

float4 main(PS_INPUT frag) : COLOR
{
    // return float4(TRANSPARENCY.x, 0.0, 0.0, 1.0);
    float smearAlpha = ease_in_out_quint(clamp(length(frag.smearAlpha.xyz), 0, 1));
    return float4(BRIGHTNESS.x * COLOR.rgb * tex2D(BASETEXTURE, frag.uv).xyz, COLOR.a * smearAlpha);
}