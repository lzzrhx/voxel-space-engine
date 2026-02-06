#version 330 core
layout (location = 0) in uint in_char;

vec4 coords[4] = vec4[4](
    vec4(-0.5, -0.5,  0.0, 0.99),
    vec4( 0.5, -0.5, 0.99, 0.99),
    vec4( 0.5,  0.5, 0.99,  0.0),
    vec4(-0.5,  0.5,  0.0,  0.0)
);

// Uniform
uniform vec2 size;
uniform vec2 ndc_pixel;
uniform float scale;
uniform vec2 pos;
uniform float spacing;

// Out
out vec2 vs_tex_coords;

void main() {
    vec2 ndc_size = ndc_pixel * size * scale;
    vec4 vert_coords = coords[gl_VertexID];
    gl_Position = vec4((vert_coords.x + gl_InstanceID + 0.5) * ndc_size.x + (pos.x + spacing * gl_InstanceID) * ndc_pixel.x - 1.0, (vert_coords.y - 0.5) * ndc_size.y - pos.y * ndc_pixel.y + 1.0, 0.0, 1.0);
    vs_tex_coords = vec2((vert_coords.z + in_char % 32u) / 32, (vert_coords.w + in_char / 32u) / 3);
}
