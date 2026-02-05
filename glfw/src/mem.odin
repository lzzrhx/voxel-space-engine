package main
import "core:mem"
import "core:log"
import "core:c/libc"

mem_check_leaks :: proc(tracking_allocator: ^mem.Tracking_Allocator) {
    for _, leak in tracking_allocator.allocation_map { log.errorf("%v: Leaked %v bytes", leak.location, leak.size) }
    mem.tracking_allocator_clear(tracking_allocator)
}

mem_check_bad_free :: proc(tracking_allocator: ^mem.Tracking_Allocator) {
    if len(tracking_allocator.bad_free_array) > 0 {
        for bad_free in tracking_allocator.bad_free_array { log.errorf("Bad free at: %v", bad_free.location) }
        libc.getchar()
        panic("Bad free detected!")
    }
}
