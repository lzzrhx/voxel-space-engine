#version 330 core

// In / Out
in float vs_depth;
in vec3 vs_color;
out vec4 fs_color;

void main() {
    gl_FragDepth = vs_depth;
    fs_color = vec4(vs_color, 1.0);
}

