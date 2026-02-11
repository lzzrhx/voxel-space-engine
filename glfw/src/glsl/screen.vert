#version 330 core

// Constants
const vec4 coords[4] = vec4[4]( vec4(-1.0, -1.0,  0.0,  1.0), vec4( 1.0, -1.0,  1.0,  1.0), vec4( 1.0,  1.0,  1.0,  0.0), vec4(-1.0,  1.0,  0.0,  0.0) );

// In / Out
out vec2 vs_tex_coords;

void main() {
    gl_Position = vec4(coords[gl_VertexID].xy, 0.0, 1.0);
    vs_tex_coords = coords[gl_VertexID].zw;
}
