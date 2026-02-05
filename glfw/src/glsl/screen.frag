#version 330 core

// In
in vec2 vs_tex_coords;

// Uniform
uniform sampler2D terrain_colorbuf;
uniform sampler2D terrain_depthbuf;

// Out
out vec4 out_frag_color;

void main()
{          
    out_frag_color = vec4(texture(terrain_colorbuf, vs_tex_coords).rgb, 1.0);
}
