#version 330 core

const vec2 coords[4] = vec2[4](
    vec2(-1.0,  1.0),
    vec2( 1.0,  1.0),
    vec2( 1.0, -1.0),
    vec2(-1.0, -1.0)
);

const float scale = 300.0;

// Uniform
uniform vec2 center_pos;
uniform mat4 view_proj_mat;

// Out
out vec3 vs_pos;

void main() {
    vs_pos = vec3(coords[gl_VertexID], 0.0).xzy * scale + vec3(center_pos, 0.0).xzy;
    gl_Position = view_proj_mat * vec4(vs_pos, 1.0);
}
