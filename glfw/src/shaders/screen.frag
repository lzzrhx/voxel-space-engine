#version 330 core

// Uniforms
uniform sampler2D render_texture;

// Ins
in vec2 vs_tex_coords;

// Outs
out vec4 frag_color;

void main()
{          
    frag_color = vec4(texture(render_texture, vs_tex_coords).rgb, 1.0);
}
