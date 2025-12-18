package main

import "core:image"
import "core:fmt"

Terrain :: struct {
    color: ^[TERRAIN_SIZE * TERRAIN_SIZE]u32,
    height: ^[TERRAIN_SIZE * TERRAIN_SIZE]u8,
}

terrain_load :: proc(terrain: ^Terrain) {
    color_img := img_load(COLORMAP_PATH)
    height_img := img_load(HEIGHTMAP_PATH)
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
    if i < len(terrain.height) {
        return terrain.height[i]
    }
    return 0
}

terrain_height_at :: proc(terrain: ^Terrain, x, y: int) -> u8 {
    return terrain_height_at_i(terrain, x + y * TERRAIN_SIZE)
}

terrain_render :: proc(world_layer: ^World_Layer, camera: ^Camera, terrain: ^Terrain) {
    camera.fog_start = world_layer.colorbuffer.height
    camera.fog_end = 0
    for x in 0 ..< world_layer.colorbuffer.width {
        dx: f32 = (camera.plx + (camera.prx - camera.plx) / f32(world_layer.colorbuffer.width) * f32(x)) / CAM_CLIP
        dy: f32 = (camera.ply + (camera.pry - camera.ply) / f32(world_layer.colorbuffer.width) * f32(x)) / CAM_CLIP
        rx := camera.x
        ry := camera.y
        irx : int
        iry : int
        z : int
        i : int
        first := true
        max_z := world_layer.colorbuffer.height
        for depth in 1 ..< int(CAM_CLIP) {
            rx += dx
            ry += dy
            irx = int(rx)
            iry = int(ry)
            if irx < 0 || irx > TERRAIN_SIZE-1 || iry < 0 || iry > TERRAIN_SIZE-1 { continue }
            i = irx + iry * TERRAIN_SIZE
            z = int((camera.z - f32(terrain.height[i])) / f32(depth) * TERRAIN_SCALE_FACTOR + camera.tilt)
            if z < 0 { z = 0 }
            else if z > world_layer.colorbuffer.height { z = world_layer.colorbuffer.height }
            if z < max_z {
                if max_z == world_layer.colorbuffer.height && (iry == TERRAIN_SIZE-1 || irx == 0 || irx == TERRAIN_SIZE-1) {
                    draw_line_at_depth(world_layer, x, z+1, max_z, int(CAM_CLIP), 0x00_00_00_00)
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
        if max_z > 0 { draw_line_at_depth(world_layer, x, 0, max_z, int(CAM_CLIP), 0x00_00_00_00) }
    }
}

