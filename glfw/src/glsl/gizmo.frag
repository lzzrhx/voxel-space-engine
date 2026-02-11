#version 330 core

// In / Out
in vec3 vs_color;
out vec4 fs_frag_color;

void main() {
    fs_frag_color = vec4(vs_color, 1.0);
}
