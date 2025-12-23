package main

import "core:image"
import "core:fmt"

Terrain :: struct {
    x: int,
    y: int,
    color: ^[TERRAIN_SIZE * TERRAIN_SIZE]u32,
    height: ^[TERRAIN_SIZE * TERRAIN_SIZE]u8,
}

terrain_load :: proc(terrain: ^Terrain, x, y: int, color_path: string = TERRAIN_DEFAULT_COLORMAP, height_path: string = TERRAIN_DEFAULT_HEIGHTMAP) {
    terrain.x = x
    terrain.y = y
    color_img := img_load(color_path)
    height_img := img_load(height_path)
    defer image.destroy(color_img)
    defer image.destroy(height_img)
    terrain.color = new([TERRAIN_SIZE * TERRAIN_SIZE]u32)
    terrain.height = new([TERRAIN_SIZE * TERRAIN_SIZE]u8)
    for i in 0 ..< TERRAIN_SIZE * TERRAIN_SIZE {
        terrain.color[i] = img_color_at_i(color_img, i)
        terrain.height[i] = height_img.pixels.buf[i*3]
    }
}

terrain_destroy :: proc(terrain: ^Terrain) {
    free(terrain.color)
    free(terrain.height)
}

terrain_height_at_i :: proc(terrain: ^Terrain, i: int) -> u8 {
    if i >= 0 && i < TERRAIN_SIZE * TERRAIN_SIZE {
        return terrain.height[i]
    }
    return 0
}

terrain_height_at :: proc(terrain: ^Terrain, x, y: f32) -> u8 {
    return terrain_height_at_i(terrain, int(x) + int(y) * TERRAIN_SIZE)
}

terrain_at_chunk_space :: proc(terrains: ^[9]Terrain, x, y: f32) -> (^Terrain, f32, f32) {
    terrain, local_x, local_y := &terrains[4], x, y
    if x < TERRAIN_SIZE {
        if y < TERRAIN_SIZE {
            terrain = &terrains[0]
        } else if y > TERRAIN_SIZE * 2 {
            local_y -= TERRAIN_SIZE * 2
            terrain = &terrains[6]
        } else {
            terrain = &terrains[3]
            local_y -= TERRAIN_SIZE
        }
    } else if x > TERRAIN_SIZE * 2 {
        local_x -= TERRAIN_SIZE * 2
        if y < TERRAIN_SIZE {
            terrain = &terrains[2]
        }
        else if y > TERRAIN_SIZE * 2 {
            local_y -= TERRAIN_SIZE * 2
            terrain = &terrains[8]
        } else {
            terrain = &terrains[5]
            local_y -= TERRAIN_SIZE
        }
    } else if y < TERRAIN_SIZE {
        local_x -= TERRAIN_SIZE
        terrain = &terrains[1]
    } else if y > TERRAIN_SIZE * 2 {
        local_y -= TERRAIN_SIZE * 2
        local_x -= TERRAIN_SIZE
        terrain = &terrains[7]
    } else {
        local_y -= TERRAIN_SIZE
        local_x -= TERRAIN_SIZE
    }
    return terrain, local_x, local_y
}

terrain_at_world_space :: proc(terrains: ^[9]Terrain, x, y :f32) -> (^Terrain, f32, f32) {
    return terrain_at_chunk_space(terrains, terrain_world_to_chunk_space(terrains, x, y))
}

terrain_local_to_world :: proc(terrain: ^Terrain, x, y : f32) -> (f32, f32) {
    return x + f32(terrain.x * TERRAIN_SIZE), y + f32(terrain.y * TERRAIN_SIZE)
}

terrain_world_to_chunk_space :: proc(terrains: ^[9]Terrain, x, y: f32) -> (f32, f32) {
    for &terrain in terrains {
        if &terrain != nil {
            return x - f32(terrain.x * TERRAIN_SIZE), y - f32(terrain.y * TERRAIN_SIZE)
        }
    }
    return x, y
}

terrain_render :: proc(world_layer: ^World_Layer, camera: ^Camera, terrains: ^[9]Terrain) {
    camera.fog_start = world_layer.colorbuffer.height
    camera.fog_end = 0
    for x in 0 ..< world_layer.colorbuffer.width {
        dx: f32 = (camera.plx + (camera.prx - camera.plx) / f32(world_layer.colorbuffer.width) * f32(x)) / CAM_CLIP
        dy: f32 = (camera.ply + (camera.pry - camera.ply) / f32(world_layer.colorbuffer.width) * f32(x)) / CAM_CLIP
        rx := camera.chunk_x
        ry := camera.chunk_y
        irx : int
        iry : int
        z : int
        i : int
        first := true
        max_z := world_layer.colorbuffer.height
        terrain : ^Terrain
        for depth in 1 ..< CAM_CLIP {
            rx += dx
            ry += dy
            irx = int(rx)
            iry = int(ry)
            terrain = &terrains[4]
            if irx < TERRAIN_SIZE || irx > TERRAIN_SIZE * 2 || iry < TERRAIN_SIZE || iry > TERRAIN_SIZE * 2 {
                if irx < TERRAIN_SIZE {
                    if iry < TERRAIN_SIZE && &terrains[0] != nil {
                        terrain = &terrains[0]
                    }
                    else if iry > TERRAIN_SIZE * 2 && &terrains[6] != nil {
                        terrain = &terrains[6]
                        iry -= TERRAIN_SIZE * 2
                    }
                    else if &terrains[3] != nil {
                        terrain = &terrains[3]
                        iry -= TERRAIN_SIZE
                    }
                    else { continue }
                } else if irx > TERRAIN_SIZE * 2 {
                    irx -= TERRAIN_SIZE * 2
                    if iry < TERRAIN_SIZE && &terrains[2] != nil {
                        terrain = &terrains[2]
                    }
                    else if iry > TERRAIN_SIZE * 2 && &terrains[8] != nil {
                        terrain = &terrains[8]
                        iry -= TERRAIN_SIZE * 2
                    }
                    else if &terrains[5] != nil {
                        terrain = &terrains[5]
                        iry -= TERRAIN_SIZE
                    }
                    else { continue }
                } else if iry < TERRAIN_SIZE {
                    if &terrains[1] != nil {
                        terrain = &terrains[1]
                        irx -= TERRAIN_SIZE
                    }
                    else { continue }
                } else {
                    iry -= TERRAIN_SIZE * 2
                    if &terrains[1] != nil {
                        terrain = &terrains[7]
                        irx -= TERRAIN_SIZE
                    }
                    else { continue }
                }
            } else {
                irx -= TERRAIN_SIZE
                iry -= TERRAIN_SIZE
            }
            if irx < 0 || irx > TERRAIN_SIZE-1 || iry < 0 || iry > TERRAIN_SIZE-1 { continue }
            i = irx + iry * TERRAIN_SIZE
            z = int((camera.z - f32(terrain.height[i])) / f32(depth) * TERRAIN_SCALE + camera.tilt)
            if z < 0 || z > world_layer.colorbuffer.height { continue }
            if z < max_z {
                if max_z == world_layer.colorbuffer.height && (iry >= TERRAIN_SIZE-2 || irx == 0 || irx == TERRAIN_SIZE-1) {
                    draw_line_at_depth(world_layer, x, z+1, max_z, CAM_CLIP, COLOR_SKY)
                    max_z = z+1
                }
                if depth > CAM_FOG_START {
                    if z < camera.fog_start { camera.fog_start = z }
                    if max_z > camera.fog_end { camera.fog_end = max_z }
                }
                draw_line_at_depth(world_layer, x, z, max_z, depth, terrain.color[i])
                max_z = z
            }
        }
        if max_z > 0 { draw_line_at_depth(world_layer, x, 0, max_z, CAM_CLIP, COLOR_SKY) }
    }
}

