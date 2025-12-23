package main

import "core:math"
import "core:fmt"

Camera :: struct {
    chunk_x: f32,
    chunk_y: f32,
    x: f32,
    y: f32,
    z: f32,
    rot: f32,
    dist: f32,
    tilt: f32,
    target_x: f32,
    target_y: f32,
    //lerp_pos: f32,
    //lerp_start_x: f32,
    //lerp_start_y: f32,
    plx: f32,
    ply: f32,
    prx: f32,
    pry: f32,
    fog_start: int,
    fog_end: int,
    txt: string,
}

camera_pos_from_target :: proc(target_x, target_y, dist, rot: f32) -> (f32, f32) {
    return target_x + dist * math.cos_f32(rot + math.PI), target_y + dist * math.sin_f32(rot + math.PI)
}

camera_update_values :: proc(terrains: ^[9]Terrain, camera: ^Camera, update_pos: bool = true) {
    if update_pos { camera.x, camera.y = camera_pos_from_target(camera.target_x, camera.target_y, camera.dist, camera.rot) }
    camera.tilt = -50.0 - (camera.z - 350.0) * 0.5 - (200.0 - camera.dist) * (camera.z / CAM_Z_MAX)
    camera.chunk_x, camera.chunk_y = terrain_world_to_chunk_space(terrains, camera.x, camera.y)
    sin := math.sin_f32(camera.rot)
    cos := math.cos_f32(camera.rot)
    camera.plx = cos * CAM_CLIP + sin * CAM_CLIP
    camera.ply = sin * CAM_CLIP - cos * CAM_CLIP
    camera.prx = cos * CAM_CLIP - sin * CAM_CLIP
    camera.pry = sin * CAM_CLIP + cos * CAM_CLIP
    camera.txt = fmt.tprintf("camera: x=%v y=%v z=%v rot=%v tilt=%v", camera.x, camera.y, camera.z, camera.rot, camera.tilt)
}

/*
camera_update :: proc(terrains: ^[9]Terrain, camera: ^Camera) {
    if camera.lerp_pos > 0.01 {
        camera.lerp_pos = math.max(camera.lerp_pos - 0.1, 0.0)
        camera.x, camera.y = camera_pos_from_target(lerp(camera.lerp_pos, camera.target_x, camera.lerp_start_x), lerp(camera.lerp_pos, camera.target_y, camera.lerp_start_y), camera.dist, camera.rot)
        camera_update_values(terrains, camera, update_pos = false)
    }
}
*/

camera_update :: proc(terrains: ^[9]Terrain, camera: ^Camera, target: ^Entity = nil) {
    if target != nil {
        camera.target_x = target.render_x
        camera.target_y = target.render_y
        camera_update_values(terrains, camera)
    }
}

camera_set :: proc(terrains: ^[9]Terrain, camera: ^Camera, x: f32 = 0.0, y: f32 = 0.0, z: f32 = (CAM_Z_MIN + CAM_Z_MAX) / 2.0, rot: f32 = 0.0, dist: f32 = (CAM_DIST_MIN + CAM_DIST_MAX) / 2.0) {
    camera.target_x = x
    camera.target_y = y
    camera.z = z
    camera.rot = math.PI * 1.5 + rot
    camera.dist = dist
    camera_update_values(terrains, camera)
}

camera_modify :: proc(terrains: ^[9]Terrain, camera: ^Camera, dx: f32 = 0.0, dy: f32 = 0.0, dz: f32 = 0.0, drot: f32 = 0.0, ddist: f32 = 0.0) {
    x, y := camera_pos_from_target(camera.target_x + dx, camera.target_y + dy, camera.dist + ddist, camera.rot + drot)
    if camera.z + dz < CAM_Z_MAX && camera.z + dz > CAM_Z_MIN && camera.dist + ddist > CAM_DIST_MIN && camera.dist + ddist < CAM_DIST_MAX && f32(terrain_height_at(terrain_at_world_space(terrains, x, y))) + CAM_HEIGHT_COLLISION < camera.z + dz {
        camera.x = x
        camera.y = y
        camera.z += dz
        camera.target_x += dx
        camera.target_y += dy
        camera.rot += drot
        camera.dist += ddist
        camera_update_values(terrains, camera, update_pos = false)
    }
}

/*
camera_move_to :: proc(terrains: ^[9]Terrain, camera: ^Camera, x, y: f32) {
    camera.lerp_start_x = camera.target_x
    camera.lerp_start_y = camera.target_y
    camera.target_x = x
    camera.target_y = y
    camera.lerp_pos = 1
}
*/

