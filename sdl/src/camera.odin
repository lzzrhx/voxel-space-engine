package main

import "core:math"
import "core:fmt"

Camera :: struct {
    x: f32,
    y: f32,
    z: f32,
    rot: f32,
    tilt: f32,
    plx: f32,
    ply: f32,
    prx: f32,
    pry: f32,
    fog_start: int,
    fog_end: int,
    txt: string,
}

camera_update :: proc(camera: ^Camera) {
    sin := math.sin_f32(camera.rot)
    cos := math.cos_f32(camera.rot)
    camera.plx = cos * CAM_CLIP + sin * CAM_CLIP
    camera.ply = sin * CAM_CLIP - cos * CAM_CLIP
    camera.prx = cos * CAM_CLIP - sin * CAM_CLIP
    camera.pry = sin * CAM_CLIP + cos * CAM_CLIP
    camera.txt = fmt.tprintf("camera: x=%v y=%v z=%v tilt=%v", camera.x, camera.y, camera.z, camera.tilt)
}

camera_move :: proc(terrain: ^Terrain, camera: ^Camera, x, y: f32) {
    if f32(terrain_height_at(terrain, int(camera.x + x), int(camera.y + y)) + 10) < camera.z {
        camera.x += x
        camera.y += y
        camera_update(camera)
    }
}

camera_change_height :: proc(terrain: ^Terrain, camera: ^Camera, z: f32) {
    if camera.z + z < 400 && camera.z + z > 100 && f32(terrain_height_at(terrain, int(camera.x), int(camera.y)) + 10) < camera.z + z {
        camera.z += z
        camera.tilt += f32(z) * -0.5
        camera_update(camera)
    }
}
