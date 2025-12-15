package main

import "core:fmt"
import "core:image"
import "core:image/png"
import "core:log"
import "core:os"

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

img_4ch_color_at :: proc(img: ^image.Image, i: int) -> (u32) {
    if i*4+2 < len(img.pixels.buf) {
        return u32(img.pixels.buf[i*4]) | u32(img.pixels.buf[i*4+1]) << 8 | u32(img.pixels.buf[i*4+2]) << 16
    }
    return 0
}
