// Defines cEyePos
#include "common_ps_fxc.h"

sampler BASETEXTURE : register(s0);

struct PS_INPUT
{
    float2 uv : TEXCOORD0;             // Position on triangle
};

float4 main(PS_INPUT frag) : COLOR
{
    return float4(tex2D(BASETEXTURE, frag.uv).xyz, 1.0);
}