package main

import "core:math"

Rect :: struct {
    x: int,
    y: int,
    width: int,
    height: int,
}

Rects :: struct {
    rects: []Rect,
    num: int,
}

int_num_digits :: proc(n: int) -> int {
    if math.abs(n) < 10 { return 1 }
    return 1 + int_num_digits(n / 10)
}

