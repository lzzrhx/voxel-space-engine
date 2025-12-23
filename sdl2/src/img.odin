package main

import "core:fmt"
import "core:image"
import "core:image/png"
import "core:log"
import "core:os"

img_load :: proc(path: string) -> ^image.Image {
    img,img_err := image.load(path, image.Options{.return_metadata, .alpha_drop_if_present})
    if img_err != nil {
        log.errorf("Couldn't load %v.", path)
        os.exit(1)
    } else {
        log.debugf("Loaded image %v: %vx%vx%v, %v-bit.", path, img.width, img.height, img.channels, img.depth)
    }
    return img
}

img_color_at_i :: proc(img: ^image.Image, i: int) -> u32 {
    if i*img.channels+img.channels-1 < len(img.pixels.buf) {
        if (img.channels == 4) { return u32(img.pixels.buf[i*img.channels]) | u32(img.pixels.buf[i*img.channels+1]) << 8 | u32(img.pixels.buf[i*img.channels+2]) << 16 | u32(img.pixels.buf[i*img.channels+3]) << 24 }
        if (img.channels == 3) { return u32(img.pixels.buf[i*img.channels]) | u32(img.pixels.buf[i*img.channels+1]) << 8 | u32(img.pixels.buf[i*img.channels+2]) << 16 }
        if (img.channels == 2) { return u32(img.pixels.buf[i*img.channels]) | u32(img.pixels.buf[i*img.channels+1]) << 8 }
        return u32(img.pixels.buf[i*img.channels])
    }
    return 0
}

img_color_at :: proc(img: ^image.Image, x, y: int) -> u32 {
    return img_color_at_i(img, x + y * img.width)
}
