package main
import "core:math/linalg/glsl"

terrain_height_at_i :: proc(heightmap: []u8, i: int) -> f32 {
    if i >= 0 && i < TERRAIN_SIZE * TERRAIN_SIZE { return f32(heightmap[i]) * 0.25 }
    return 0
}

terrain_height_at :: proc(heightmap: []u8, pos: glsl.vec2) -> f32 {
    return terrain_height_at_i(heightmap, int(pos.x) + int(pos.y) * TERRAIN_SIZE)
}
