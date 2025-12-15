package main

import "core:math"

draw_pixel :: proc(colorbuffer: []u32, x, y: int, color: u32) {
    if x > 0 && x < WINDOW_WIDTH && y > 0 && y < WINDOW_HEIGHT {
        colorbuffer[int(x + y * WINDOW_WIDTH)] = color
    }
}

draw_line :: proc(colorbuffer: []u32, x0, y0, x1, y1: int, color: u32) {
    dx: f32 = f32(x1 - x0)
    dy: f32 = f32(y1 - y0)
    step := math.abs(dx) >= math.abs(dy) ? math.abs(dx) : math.abs(dy)
    dx /= step
    dy /= step
    x: f32 = f32(x0)
    y: f32 = f32(y0)
    for i in 0 ..= int(step) {
        draw_pixel(colorbuffer, int(math.round_f32(x)), int(math.round_f32(y)), color)
        x += dx
        y += dy
    }
}
