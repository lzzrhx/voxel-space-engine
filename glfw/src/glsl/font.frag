#version 330 core

// In / Out
in vec2 vs_tex_coords;
out vec4 fs_color;

// Uniforms
uniform sampler2D font_tex;
uniform vec3 color;

void main() {
    fs_color = vec4(color, texture(font_tex, vs_tex_coords).r);
}
