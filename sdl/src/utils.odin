package main

import "core:math"

int_num_digits :: proc(n: int) -> int {
    if math.abs(n) < 10 { return 1 }
    return 1 + int_num_digits(n / 10)
}

