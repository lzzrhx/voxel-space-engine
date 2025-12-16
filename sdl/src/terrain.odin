package main

import "core:image"

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

terrain_height_at_x_y :: proc(terrain: ^Terrain, x, y: f32) -> u8 {
    return terrain_height_at_i(terrain, int(x) & (TERRAIN_SIZE-1) + (int(y) & (TERRAIN_SIZE-1)) * TERRAIN_SIZE)
}

terrain_render :: proc(colorbuffer: []u32, camera: ^Camera, terrain: ^Terrain) {
    for x in 0 ..< RENDER_WIDTH {
        dx: f32 = (camera.plx + (camera.prx - camera.plx) / f32(RENDER_WIDTH) * f32(x)) / camera.clip
        dy: f32 = (camera.ply + (camera.pry - camera.ply) / f32(RENDER_WIDTH) * f32(x)) / camera.clip
        rx := camera.x
        ry := camera.y
        irx : int
        iry : int
        z : int
        i : int
        first := true
        max_z: int = RENDER_HEIGHT
        for depth in 1 ..< int(camera.clip) {
            rx += dx
            ry += dy
            irx = int(rx)
            iry = int(ry)
            if irx < 0 || irx > TERRAIN_SIZE-1 || iry < 0 || iry > TERRAIN_SIZE-1 { continue }
            i = irx + iry * TERRAIN_SIZE
            z = int((camera.z - f32(terrain.height[i])) / f32(depth) * SCALE_FACTOR + camera.tilt)
            if z < 0 { z = 0 }
            else if z > RENDER_HEIGHT { z = RENDER_HEIGHT }
            if z < max_z {
                if max_z == RENDER_HEIGHT && (iry == TERRAIN_SIZE-1 || irx == 0 || irx == TERRAIN_SIZE-1) { 
                    max_z = z+1
                }
                for y in z ..< max_z {
                    draw_pixel(colorbuffer[:], x, y, img_color_at(terrain.colormap, i))
                }
                max_z = z
            }
        }
    }
}

