package main

import "core:math"

Rect :: struct {
    x: int,
    y: int,
    width: int,
    height: int,
}

Collection :: struct($T: typeid, $N: int) where N >= 0 {
    data: ^[N]T,
    num: int,
}

int_num_digits :: proc(n: int) -> int {
    if math.abs(n) < 10 { return 1 }
    return 1 + int_num_digits(n / 10)
}

min :: proc(a, b: $T) -> T {
    return a < b ? a : b
}

max :: proc(a, b: $T) -> T {
    return b > a ? b : a
}


dot :: proc(x0, y0, x1, y1: f32) -> f32 {
    return x0 * x1 + y0 * y1
}

mag :: proc(x, y: f32) -> f32 {
    return math.sqrt_f32(x * x + y * y)
}

/*
vec2_dist :: proc(x0, y0, x1, y1: f32) -> f32 {
    return math.sqrt_f32(math.pow2_f32(x1-x0) + math.pow2_f32(y1-y0))
}
*/

/*
// cubic polynomial smoothstep
smoothstep :: proc(x: f32) -> f32 {
    return x * x * (3 - 2 * x)
}
*/

lerp :: proc(val, min, max: $T) -> T {
    return (max - min) * val + min
}
