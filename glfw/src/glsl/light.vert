#version 330 core

// In
layout (location = 0) in vec3 in_pos;
layout (location = 1) in vec3 in_normal;
layout (location = 2) in vec2 in_tex_coords;

// Uniform
uniform mat4 model_mat;
uniform mat4 view_mat;
uniform mat4 proj_mat;

// Out
out vec2 vs_tex_coords;

void main()
{
    gl_Position = proj_mat * view_mat * model_mat * vec4(in_pos, 1.0);
    vs_tex_coords = in_tex_coords;
}

