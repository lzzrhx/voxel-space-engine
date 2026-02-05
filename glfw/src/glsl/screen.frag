#version 330 core

// 2x2 dither pattern
const float DITHER_2_0_0 = 0.0/1.0;
const float DITHER_2_1_0 = 2.0/1.0;
const float DITHER_2_0_1 = 3.0/1.0;
const float DITHER_2_1_1 = 1.0/1.0;
const float DITHER_2_MAX = 3.0/1.0;

// In
in vec2 vs_tex_coords;

// Uniform
uniform sampler2D terrain_colorbuf;
uniform sampler2D terrain_depthbuf;
uniform vec3 sky_color;
uniform float fog_start;
uniform vec2 window_world_ratio;

// Out
out vec4 out_frag_color;

float smoothstep_q_r(float x) {
  return x*x/(2.0*x*x-2.0*x+1.0);
}

void main()
{
    float depth = texture(terrain_depthbuf, vs_tex_coords).r;
    //float side_bias = 0.6 + 0.4 * smoothstep_q_r(1.0 - abs(vs_tex_coords.x - 0.5) * 2);
    //float fog = fog_start * side_bias;
    if (depth < fog_start) {
        out_frag_color = vec4(texture(terrain_colorbuf, vs_tex_coords).rgb, 1.0);
    } else {
        float fog_depth = (depth - fog_start) / (1.0 - fog_start) * DITHER_2_MAX;
        int x = int(gl_FragCoord.x / window_world_ratio.x);
        int y = int(gl_FragCoord.y / window_world_ratio.y);
        float dither_val = x % 2 == 1 && y %  2 == 0 ? DITHER_2_1_0 : (x % 2 == 0 && y % 2 == 1 ? DITHER_2_0_1 : (x % 2 == 1 && y % 2 == 1 ? DITHER_2_1_1 : DITHER_2_0_0));
        vec3 color = fog_depth > dither_val ? sky_color : texture(terrain_colorbuf, vs_tex_coords).rgb;
        out_frag_color = vec4(color, 1.0);
    }
}
