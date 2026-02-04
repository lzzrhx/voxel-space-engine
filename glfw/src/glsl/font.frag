#version 330 core

// In
in vec2 vs_tex_coords;

// Uniform
uniform sampler2D texture_font;
uniform vec3 font_color;

// Out
out vec4 out_frag_color;

void main()
{
    out_frag_color = vec4(font_color, texture(texture_font, vs_tex_coords).r);
}
