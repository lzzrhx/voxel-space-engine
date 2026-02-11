#version 330 core

// Constants
const vec2 coords[4] = vec2[4]( vec2(-1.0,  1.0), vec2( 1.0,  1.0), vec2( 1.0, -1.0), vec2(-1.0, -1.0) );

// In / Out
out vec2 vs_pos;

// Uniforms
uniform mat4 pv_mat;
uniform float terrain_size;

void main() {
    vs_pos = coords[gl_VertexID];
    gl_Position = pv_mat * vec4(vec3(vs_pos * terrain_size * 0.5 + terrain_size * 0.5 , 0.0).xzy, 1.0);
}
