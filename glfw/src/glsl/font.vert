#version 330 core

vec4 coords[4] = vec4[4](
    vec4(-1.0, -1.0,  0.0, 0.99),
    vec4( 1.0, -1.0, 0.99, 0.99),
    vec4( 1.0,  1.0, 0.99,  0.0),
    vec4(-1.0,  1.0,  0.0,  0.0)
);

// Uniform
uniform int char_code;
uniform mat4 font_mat;

// Out
out vec2 vs_tex_coords;

void main() {
    vec4 vert_coords = coords[gl_VertexID];
    gl_Position = font_mat * vec4(vert_coords.xy, 0.0, 1.0);
    vs_tex_coords = vec2((vert_coords.z + char_code % 32) / 32, (vert_coords.w + char_code / 32) / 3);
}
