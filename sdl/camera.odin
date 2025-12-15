package main

import "core:math"

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
}

camera_update :: proc(camera: ^Camera) {
    sin := math.sin_f32(camera.rot)
    cos := math.cos_f32(camera.rot)
    camera.plx = cos * camera.clip + sin * camera.clip
    camera.ply = sin * camera.clip - cos * camera.clip
    camera.prx = cos * camera.clip - sin * camera.clip
    camera.pry = sin * camera.clip + cos * camera.clip
}
