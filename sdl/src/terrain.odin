package main

import "core:image"
import "core:fmt"

Terrain :: struct {
    colormap: ^image.Image,
    height: ^[TERRAIN_SIZE * TERRAIN_SIZE]u8,
}

terrain_load :: proc(terrain: ^Terrain) {
    terrain.colormap = img_load(COLORMAP_PATH)
    heightmap := img_load(HEIGHTMAP_PATH)
    defer image.destroy(heightmap)
    terrain.height = new([TERRAIN_SIZE * TERRAIN_SIZE]u8)
    for i in 0 ..< len(terrain.height) {
        terrain.height[i] = heightmap.pixels.buf[i*3]
    }
}

terrain_destroy :: proc(terrain: ^Terrain) {
    image.destroy(terrain.colormap)
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
    for x in 0 ..< world_layer.colorbuffer.width {
        dx: f32 = (camera.plx + (camera.prx - camera.plx) / f32(world_layer.colorbuffer.width) * f32(x)) / camera.clip
        dy: f32 = (camera.ply + (camera.pry - camera.ply) / f32(world_layer.colorbuffer.width) * f32(x)) / camera.clip
        rx := camera.x
        ry := camera.y
        irx : int
        iry : int
        z : int
        i : int
        first := true
        max_z: int = world_layer.colorbuffer.height
        for depth in 1 ..< int(camera.clip) {
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
                if max_z == world_layer.colorbuffer.height && (iry == TERRAIN_SIZE-1 || irx == 0 || irx == TERRAIN_SIZE-1) { max_z = z+1 }
                for y in z ..< max_z {
                    draw_pixel(world_layer.colorbuffer, x, y, img_color_at_i(terrain.colormap, i))
                    draw_depthbuffer_pixel(world_layer.depthbuffer, x, y, depth)
                }
                max_z = z
            }
        }
    }
}

