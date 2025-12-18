DIGIT_0 :u64: 0b01111100_10001010_10010010_10100010_01111100
DIGIT_1 :u64: 0b00000000_01000010_11111110_00000010_00000000
DIGIT_2 :u64: 0b01000110_10001010_10010010_10100010_01000010
DIGIT_3 :u64: 0b01000100_10000010_10010010_10010010_01101100
DIGIT_4 :u64: 0b00011000_00101000_01001000_11111110_00001000
DIGIT_5 :u64: 0b11100100_10010010_10010010_10010010_10001100
DIGIT_6 :u64: 0b01111100_10010010_10010010_10010010_00001100
DIGIT_7 :u64: 0b10000110_10001000_10010000_10100000_11000000
DIGIT_8 :u64: 0b01101100_10010010_10010010_10010010_01101100
DIGIT_9 :u64: 0b01100000_10010010_10010010_10010010_01111100

// Draw 8x5 digits
draw_digit_small :: proc(colorbuffer: []u32, n, x, y: int, color: u32) {
    bits := DIGIT_0
    switch n {
    case 1:
        bits = DIGIT_1
    case 2:
        bits = DIGIT_2
    case 3:
        bits = DIGIT_3
    case 4:
        bits = DIGIT_4
    case 5:
        bits = DIGIT_5
    case 6:
        bits = DIGIT_6
    case 7:
        bits = DIGIT_7
    case 8:
        bits = DIGIT_8
    case 9:
        bits = DIGIT_9
    }
    for i in 0 ..< 5 {
        for j in 0 ..< 8 {
            bit := u64(0b10000000_00000000_00000000_00000000_00000000) >> u64(j+i*8)
            if bits & bit == bit {
                draw_pixel(colorbuffer, x + i, y + j, color)
            }
        }
    } 
}

// Convert 16x8 font in .png format to u128 bits
convert_png_to_bits :: proc() {
    img := img_load("chars.png")
    defer image.destroy(img)
    for i in 0 ..< img.width / 8 {
        n: u128 = 0
        for x in 0 ..< 8 {
            for y in 0 ..< 16 {
                if img.pixels.buf[(x+i*8+y*img.width)*img.channels] > 0 {
                    n = n | u128(0b10000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_0000000_00000000_00000000_00000000_000000000) >> u128(y+x*16)
                }
            }
        }
        fmt.printf("CHAR_%v :u128: %#b\n",i,n)
    }
}

//camera_move(game.terrain, game.camera, -math.cos_f32(game.camera.rot) * CAM_SPEED, -math.sin_f32(game.camera.rot) * CAM_SPEED)
//camera_move(game.terrain, game.camera, math.cos_f32(game.camera.rot) * CAM_SPEED, math.sin_f32(game.camera.rot) * CAM_SPEED)

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
