#version 330 core

// In / Out
in float vs_depth;
out vec4 fs_color;

//Uniforms
uniform vec3 color;

void main() {
    gl_FragDepth = vs_depth;
    fs_color = vec4(color, 1.0);
}
