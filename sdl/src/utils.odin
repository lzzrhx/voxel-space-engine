package main

import "core:fmt"
import "core:image"
import "core:image/png"
import "core:log"
import "core:os"
import "core:math"

img_load :: proc(path: string) -> ^image.Image {
    img,img_err := image.load(path, image.Options{.return_metadata})
    if img_err != nil {
        log.errorf("Couldn't load %v.", path)
        os.exit(1)
    } else {
        fmt.printf("Loaded image %v: %vx%vx%v, %v-bit.\n", path, img.width, img.height, img.channels, img.depth)
    }
    return img
}

img_color_at_i :: proc(img: ^image.Image, i: int) -> u32 {
    if i*img.channels+2 < len(img.pixels.buf) {
        return u32(img.pixels.buf[i*img.channels]) | u32(img.pixels.buf[i*img.channels+1]) << 8 | u32(img.pixels.buf[i*img.channels+2]) << 16
    }
    return 0
}

img_color_at :: proc(img: ^image.Image, x, y: int) -> u32 {
    return img_color_at_i(img, x + y * img.width)
}

int_digits :: proc(n: int) -> int {
    if math.abs(n) < 10 { return 1 }
    return 1 + int_digits(n / 10)
}

color_set_brightness :: proc(color: ^u32, brightness: f32) {
    r := f32(f32(color^ & u32(0x00_00_00_FF)) * brightness)
    if r < 0.0 { r = 0.0 }
    else if r > 255.0 { r = 255.0}
    g := f32(f32((color^ & u32(0x00_00_FF_00)) >> 8) * brightness)
    if g < 0.0 { g = 0.0 }
    else if g > 255.0 { g = 255.0}
    b := f32(f32((color^ & u32(0x00_FF_00_00)) >> 16) * brightness)
    if b < 0.0 { b = 0.0 }
    else if b > 255.0 { b = 255.0}
    color^ = u32(r) | (u32(g) << 8) | (u32(b) << 16)
}
