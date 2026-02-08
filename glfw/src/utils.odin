package main
import "core:math"

u32_num_digits :: proc(n: u32) -> u32 {
    if n < 10 { return 1 }
    return 1 + u32_num_digits(n / 10)
}

dot2 :: proc(x0, y0, x1, y1: f32) -> f32 {
    return x0 * x1 + y0 * y1
}

mag2 :: proc(x, y: f32) -> f32 {
    return math.sqrt_f32(x * x + y * y)
}
