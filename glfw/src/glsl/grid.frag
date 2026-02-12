#version 330 core

// Constants
const uint scale = 4u;

// In / Out
in vec2 vs_pos;
out vec4 fs_color;

// Uniforms
uniform float terrain_size;
uniform uint tile_size;

void main() {
    uvec2 terrain_pos = uvec2((vs_pos.x + 1.0) * 0.5 * 1024.0 * float(scale), (vs_pos.y + 1.0) * 0.5 * 1024.0 * float(scale));
    fs_color = vec4(vec3(1.0), (terrain_pos.x % (tile_size * scale) == 0u || terrain_pos.y % (tile_size * scale) == 0u) ? 0.25 : 0.0);
}
