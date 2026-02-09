package main
import "core:math/linalg/glsl"
import "core:math"
import "core:fmt"

Camera :: struct {
    pos:    glsl.vec2,
    z:      f32,
    rot:    glsl.vec2,
    dist:   f32,
    target: glsl.vec2,
    clip_l: glsl.vec2,
    clip_r: glsl.vec2,
}

camera_pos_from_target :: proc(target: glsl.vec2, dist, rot: f32) -> glsl.vec2 {
    return {target.x + dist * math.cos_f32(rot + math.PI), target.y + dist * math.sin_f32(rot + math.PI)}
}

camera_update_values :: proc(camera: ^Camera, update_pos: bool = true) {
    if update_pos { camera.pos = camera_pos_from_target(camera.target, camera.dist, camera.rot.y) }
    camera.rot.x = -50.0 - (camera.z - 350.0) * 0.5 - (200.0 - camera.dist) * (camera.z / CAM_Z_MAX)
    sin := math.sin_f32(camera.rot.y)
    cos := math.cos_f32(camera.rot.y)
    camera.clip_l = {cos * CAM_CLIP + sin * CAM_CLIP, sin * CAM_CLIP - cos * CAM_CLIP}
    camera.clip_r = {cos * CAM_CLIP - sin * CAM_CLIP, sin * CAM_CLIP + cos * CAM_CLIP}
}

camera_set :: proc(camera: ^Camera, pos: glsl.vec2, z: f32 = (CAM_Z_MIN + CAM_Z_MAX) / 2.0, rot: f32 = 0.0, dist: f32 = (CAM_DIST_MIN + CAM_DIST_MAX) / 2.0) {
    camera.target = pos
    camera.z = z
    camera.rot.y = math.PI * 1.5 + rot
    camera.dist = dist
    camera_update_values(camera)
}

camera_modify :: proc(camera: ^Camera, dpos: glsl.vec2 = {0.0, 0.0}, dz: f32 = 0.0, drot: f32 = 0.0, ddist: f32 = 0.0) {
    new_pos := camera_pos_from_target(camera.target + dpos, camera.dist + ddist, camera.rot.y + drot)
    if camera.z + dz < CAM_Z_MAX && camera.z + dz > CAM_Z_MIN && camera.dist + ddist > CAM_DIST_MIN && camera.dist + ddist < CAM_DIST_MAX {
        camera.pos = new_pos
        camera.z += dz
        camera.target += dpos
        camera.rot.y += drot
        camera.dist += ddist
        camera_update_values(camera, update_pos = false)
    }
}
