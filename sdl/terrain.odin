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

terrain_render :: proc(colorbuffer: []u32, camera: ^Camera, terrain: ^Terrain) {
    for x in 0 ..< WINDOW_WIDTH {
        dx: f32 = (camera.plx + (camera.prx - camera.plx) / f32(WINDOW_WIDTH) * f32(x)) / camera.clip
        dy: f32 = (camera.ply + (camera.pry - camera.ply) / f32(WINDOW_WIDTH) * f32(x)) / camera.clip
        rx := camera.x
        ry := camera.y
        max_height: int = WINDOW_HEIGHT
        for z in 1 ..< camera.clip {
            rx += dx
            ry += dy
            i: int = (int(rx) & (TERRAIN_SIZE-1)) + (int(ry) & (TERRAIN_SIZE-1)) * TERRAIN_SIZE
            height: int = int((camera.z - f32(terrain.height[i])) / f32(z) * f32(SCALE_FACTOR) + camera.tilt)
            if height < 0 {
                height = 0
            }
            if height > WINDOW_HEIGHT {
                height = WINDOW_HEIGHT - 1
            }
            if height < max_height {
                for y in height ..< max_height {
                    draw_pixel(colorbuffer[:], x, y, img_4ch_color_at(terrain.colormap, i))
                }
                max_height = height
            }
        }
    }
}

