package main

import "core:math"
import "core:fmt"

Camera :: struct {
    x: f32,
    y: f32,
    z: f32,
    rot: f32,
    tilt: f32,
    clip: f32,
    plx: f32,
    ply: f32,
    prx: f32,
    pry: f32,
    txt: string,
}

camera_move :: proc(terrain: ^Terrain, camera: ^Camera, x, y: f32) {
    if f32(terrain_height_at_x_y(terrain, camera.x + x, camera.y + y) + 10) < camera.z {
        camera.x += x
        camera.y += y
        camera_update(camera)
    }
}

camera_change_height :: proc(terrain: ^Terrain, camera: ^Camera, z: f32) {
    if camera.z + z < 400 && camera.z + z > 100 && f32(terrain_height_at_x_y(terrain, camera.x, camera.y) + 10) < camera.z + z {
        camera.z += z
        camera.tilt += f32(z) * -0.5
        camera_update(camera)
    }
}

camera_update :: proc(camera: ^Camera) {
    sin := math.sin_f32(camera.rot)
    cos := math.cos_f32(camera.rot)
    camera.plx = cos * camera.clip + sin * camera.clip
    camera.ply = sin * camera.clip - cos * camera.clip
    camera.prx = cos * camera.clip - sin * camera.clip
    camera.pry = sin * camera.clip + cos * camera.clip
    camera.txt = fmt.tprintf("camera: x=%v y=%v z=%v tilt=%v", camera.x, camera.y, camera.z, camera.tilt)
}
