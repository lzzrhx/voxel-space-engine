#version 330 core

// Constants
const vec3 coords[4] = vec3[4](
    vec3(0.0, 0.0, 0.0),
    vec3(1.0, 0.0, 0.0),
    vec3(0.0, 1.0, 0.0),
    vec3(0.0, 0.0, 1.0)
);
const vec3 colors[3] = vec3[3](
    vec3(1.0, 0.0, 0.0),
    vec3(0.0, 1.0, 0.0),
    vec3(0.0, 0.0, 1.0)
);

// In / Out
out vec3 vs_color;

// Uniforms
uniform mat4 pv_mat;
uniform vec2 pos;
const float size = 12.0;

void main() {
    vs_color = colors[gl_VertexID / 2];
    gl_Position = pv_mat * vec4(coords[(gl_VertexID / 2 + 1) * (gl_VertexID % 2)] * size + vec3(pos, 0.0).xzy, 1.0);
}
