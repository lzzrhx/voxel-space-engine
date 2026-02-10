#version 330 core

// In
layout (location = 0) in vec3 in_pos;
layout (location = 1) in vec3 in_normal;
layout (location = 2) in vec2 in_tex_coords;

// Uniform
uniform mat4 model_mat;
uniform mat4 ndc_mat;

// Out
out vec4 vs_pos;

void main()
{
    vs_pos = model_mat * vec4(in_pos, 1.0);
    gl_Position = ndc_mat * vs_pos;
}

