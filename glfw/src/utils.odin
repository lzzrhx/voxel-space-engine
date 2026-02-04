package main
import "core:math"


u32_num_digits :: proc(n: u32) -> u32 {
    if n < 10 { return 1 }
    return 1 + u32_num_digits(n / 10)
}
