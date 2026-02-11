#version 330 core

// In / Out
layout (location = 0) in vec3 in_pos;
layout (location = 1) in vec3 in_normal;
layout (location = 2) in vec2 in_tex_coords;
out float vs_depth;

// Uniforms
uniform mat4 model_mat;
uniform mat4 pv_mat;
uniform float clip;

void main() {
    gl_Position = pv_mat * model_mat * vec4(in_pos, 1.0);
    vs_depth = gl_Position.z / clip;
}
