#version 330 core

// Constants (2x2 dither pattern)
const float DITHER_2_0_0 = 0.0/1.0;
const float DITHER_2_1_0 = 2.0/1.0;
const float DITHER_2_0_1 = 3.0/1.0;
const float DITHER_2_1_1 = 1.0/1.0;
const float DITHER_2_MAX = 3.0/1.0;

// In / Out
in float vs_depth;
in vec3 vs_color;
out vec4 fs_color;

// Uniforms
uniform float fog_start;

// Cubic Polynomial Smoothstep
float cp_smoothstep(float x) { return x*x*(3.0-2.0*x); }

// Cubic Rational Smoothstep
float cr_smoothstep(float x) { return x*x*x/(3.0*x*x-3.0*x+1.0); }

void main() {
    gl_FragDepth = vs_depth;
    uint x = uint(gl_FragCoord.x);
    uint y = uint(gl_FragCoord.y);
    float dither_val = x % 2u == 1u && y %  2u == 0u ? DITHER_2_1_0 : (x % 2u == 0u && y % 2u == 1u ? DITHER_2_0_1 : (x % 2u == 1u && y % 2u == 1u ? DITHER_2_1_1 : DITHER_2_0_0));
    float depth_a = (1.0 - (vs_depth - fog_start) / (1.0 - fog_start));
    float a = vs_depth > fog_start ? (vs_depth > dither_val ? cr_smoothstep(depth_a) : cp_smoothstep(depth_a) ) : 1.0;
    fs_color = vec4(vs_color, a);
}

