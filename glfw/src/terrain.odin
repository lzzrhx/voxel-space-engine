package main
import "core:math/linalg/glsl"

terrain_height_at_i :: proc(heightmap: []u8, i: int) -> u8 {
    if i >= 0 && i < TERRAIN_SIZE * TERRAIN_SIZE { return heightmap[i] }
    return 0
}

terrain_height_at :: proc(heightmap: []u8, pos: glsl.vec2) -> u8 {
    return terrain_height_at_i(heightmap, int(pos.x) + int(pos.y) * TERRAIN_SIZE)
}
