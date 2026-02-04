package main
import "core:math/linalg/glsl"

Camera :: struct {
    chunk_pos: glsl.vec2,
    pos: glsl.vec3,
    rot: f32,
    //dist: f32,
    tilt: f32,
    //target: glsl.vec2,
    clip_l: glsl.vec2,
    clip_r: glsl.vec2,
    //fog_start: u32,
    //fog_end: u32,
    //txt: string,
}
