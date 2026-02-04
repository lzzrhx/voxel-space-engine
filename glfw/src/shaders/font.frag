#version 330 core

// Uniforms
uniform sampler2D font_texture;
uniform vec3 font_color;

// Ins
in vec2 vs_tex_coords;

// Outs
out vec4 out_frag_color;

void main()
{
    out_frag_color = vec4(font_color, texture(font_texture, vs_tex_coords).r);
}
