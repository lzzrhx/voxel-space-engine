#version 330 core

vec4 coords[4] = vec4[4](
    vec4(-1.0, -1.0,  0.0, 0.99),
    vec4( 1.0, -1.0, 0.99, 0.99),
    vec4( 1.0,  1.0, 0.99,  0.0),
    vec4(-1.0,  1.0,  0.0,  0.0)
);

// Uniforms
uniform int character;
uniform mat4 font_mat;

// Outs
out vec2 vs_tex_coords;

void main() {
    vec4 c = coords[gl_VertexID];
    gl_Position = font_mat * vec4(c.xy, 0.0, 1.0);
    vs_tex_coords = vec2((c.z + character % 32) / 32, (c.w + character / 32) / 3);
}
