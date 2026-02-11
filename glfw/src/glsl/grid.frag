#version 330 core

// Constants
const float scale = 4.0;

// In / Out
in vec2 vs_pos;
out vec4 fs_frag_color;

// Uniforms
uniform float terrain_size;
uniform uint tile_size;

void main() {
    uvec2 terrain_pos = uvec2((vs_pos.x + 1.0) * 0.5 * 1024.0 * scale, (vs_pos.y + 1.0) * 0.5 * 1024.0 * scale);
    fs_frag_color = vec4(vec3(1.0), (terrain_pos.x % (tile_size * uint(scale)) == 0u || terrain_pos.y % (tile_size * uint(scale)) == 0u) ? 0.25 : 0.0);
}
