package main

import "core:math"
import "core:strings"
import "core:image"
import "vendor:sdl2"
import "core:fmt"

Colorbuffer :: struct {
    buf: []u32,
    texture: ^sdl2.Texture,
    width: int,
    height: int,
}

Depthbuffer :: struct {
    buf: []u16,
    width: int,
    height: int,
}

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

draw_pixel :: proc(colorbuffer: ^Colorbuffer, x, y: int, color: u32) {
    if x >= 0 && x < colorbuffer.width && y >= 0 && y < colorbuffer.width {
        if (color != TRANSPARENT_COLOR) { colorbuffer.buf[int(x + y * colorbuffer.width)] = color }
    }
}

draw_line :: proc(colorbuffer: ^Colorbuffer, x0, y0, x1, y1: int, color: u32) {
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

draw_depthbuffer_pixel :: proc(depthbuffer: ^Depthbuffer, x, y, depth: int) {
    if x >= 0 && x < depthbuffer.width && y >= 0 && y < depthbuffer.height && depth > 0 {
        depthbuffer.buf[x + y * depthbuffer.width] = u16(depth)
    }
}

draw_pixel_at_depth :: proc(world_layer: ^World_Layer, x, y, depth: int, color: u32) {
    if x >= 0 && x < world_layer.depthbuffer.width && y >= 0 && y < world_layer.depthbuffer.height && depth > 0 {
        if world_layer.depthbuffer.buf[x + y * world_layer.depthbuffer.width] > u16(depth) {
            draw_pixel(world_layer.colorbuffer, x, y, color)
        }
    }
}

draw_img_at_depth :: proc(world_layer: ^World_Layer, img: ^image.Image, x, y: int, depth: f32) {
    if int(depth) > 0 {
        scale := f32(world_layer.colorbuffer.width) * 0.5 / depth
        width := int(f32(img.width) * scale)
        height := int(f32(img.height) * scale)
        for img_x in 0 ..< width {
            img_pixel_x := int(f32(img_x) / scale)
            for img_y in 0 ..< height {
                // TODO: fix stuttering from the color lookup
                color := img_color_at(img, img_pixel_x, int(f32(img_y) / scale))
                draw_pixel_at_depth(world_layer, x + img_x, y - height + img_y, int(depth), color)
            }
        }
    }
}

draw_u128 :: proc(colorbuffer: ^Colorbuffer, bits: u128, x, y: int, color: u32) {
    for i in 0 ..< 8 {
        for j in 0 ..< 16 {
            bit := u128(0b10000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_0000000_00000000_00000000_00000000_000000000) >> u128(j+i*16)
            if bits & bit == bit {
                draw_pixel(colorbuffer, x + i, y + j, color)
            }
        }
    }
}

draw_digit :: proc(colorbuffer: ^Colorbuffer, n, x, y: int, color: u32) {
    bits := CHAR_0
    switch n {
    case 1: bits = CHAR_1
    case 2: bits = CHAR_2
    case 3: bits = CHAR_3
    case 4: bits = CHAR_4
    case 5: bits = CHAR_5
    case 6: bits = CHAR_6
    case 7: bits = CHAR_7
    case 8: bits = CHAR_8
    case 9: bits = CHAR_9
    }
    draw_u128(colorbuffer, bits, x, y, color)
}

draw_rune :: proc(colorbuffer: ^Colorbuffer, letter: rune, x, y: int, color: u32) {
    bits := CHAR_QUESTION
    switch letter {
    case '0': bits = CHAR_0
    case '1': bits = CHAR_1
    case '2': bits = CHAR_2
    case '3': bits = CHAR_3
    case '4': bits = CHAR_4
    case '5': bits = CHAR_5
    case '6': bits = CHAR_6
    case '7': bits = CHAR_7
    case '8': bits = CHAR_8
    case '9': bits = CHAR_9
    case 'a': bits = CHAR_LC_A
    case 'b': bits = CHAR_LC_B
    case 'c': bits = CHAR_LC_C
    case 'd': bits = CHAR_LC_D
    case 'e': bits = CHAR_LC_E
    case 'f': bits = CHAR_LC_F
    case 'g': bits = CHAR_LC_G
    case 'h': bits = CHAR_LC_H
    case 'i': bits = CHAR_LC_I
    case 'j': bits = CHAR_LC_J
    case 'k': bits = CHAR_LC_K
    case 'l': bits = CHAR_LC_L
    case 'm': bits = CHAR_LC_M
    case 'n': bits = CHAR_LC_N
    case 'o': bits = CHAR_LC_O
    case 'p': bits = CHAR_LC_P
    case 'q': bits = CHAR_LC_Q
    case 'r': bits = CHAR_LC_R
    case 's': bits = CHAR_LC_S
    case 't': bits = CHAR_LC_T
    case 'u': bits = CHAR_LC_U
    case 'v': bits = CHAR_LC_V
    case 'w': bits = CHAR_LC_W
    case 'x': bits = CHAR_LC_X
    case 'y': bits = CHAR_LC_Y
    case 'z': bits = CHAR_LC_Z
    case 'A': bits = CHAR_A
    case 'B': bits = CHAR_B
    case 'C': bits = CHAR_C
    case 'D': bits = CHAR_D
    case 'E': bits = CHAR_E
    case 'F': bits = CHAR_F
    case 'G': bits = CHAR_G
    case 'H': bits = CHAR_H
    case 'I': bits = CHAR_I
    case 'J': bits = CHAR_J
    case 'K': bits = CHAR_K
    case 'L': bits = CHAR_L
    case 'M': bits = CHAR_M
    case 'N': bits = CHAR_N
    case 'O': bits = CHAR_O
    case 'P': bits = CHAR_P
    case 'Q': bits = CHAR_Q
    case 'R': bits = CHAR_R
    case 'S': bits = CHAR_S
    case 'T': bits = CHAR_T
    case 'U': bits = CHAR_U
    case 'V': bits = CHAR_V
    case 'W': bits = CHAR_W
    case 'X': bits = CHAR_X
    case 'Y': bits = CHAR_Y
    case 'Z': bits = CHAR_Z
    case '+': bits = CHAR_PLUS
    case '\\': bits = CHAR_BACKSLASH
    case '!': bits = CHAR_EXCLAMATION
    case '"': bits = CHAR_QUOTATION
    case '#': bits = CHAR_HASH
    case '%': bits = CHAR_PERCENT
    case '&': bits = CHAR_AMPERSAND
    case '/': bits = CHAR_SLASH
    case '(': bits = CHAR_L_PAR
    case ')': bits = CHAR_R_PAR
    case '=': bits = CHAR_EQ
    case '?': bits = CHAR_QUESTION
    case '`': bits = CHAR_BACKTICK
    case '@': bits = CHAR_AT
    case '$': bits = CHAR_DOLLAR
    case '{': bits = CHAR_L_CURLY_BRACKET
    case '[': bits = CHAR_L_BRACKET
    case ']': bits = CHAR_R_BRACKET
    case '}': bits = CHAR_R_CURLY_BRACKET
    case '^': bits = CHAR_CARET
    case '~': bits = CHAR_TILDE
    case '*': bits = CHAR_ASTERISK
    case '\'': bits = CHAR_APOSTROPHE
    case ',': bits = CHAR_COMMA
    case ';': bits = CHAR_SEMICOLON
    case '.': bits = CHAR_DOT
    case ':': bits = CHAR_COLON
    case '-': bits = CHAR_MINUS
    case '_': bits = CHAR_UNDERSCORE
    case '<': bits = CHAR_LT
    case '>': bits = CHAR_GT
    case '☺': bits = CHAR_SMILE1
    case '☻': bits = CHAR_SMILE2
    case '♥': bits = CHAR_HEART
    case '♦': bits = CHAR_DIAMONDS
    case '♣': bits = CHAR_CLUBS
    case '♠': bits = CHAR_SPADES
    case '•': bits = CHAR_BULLET
    case '♂': bits = CHAR_MALE
    case '♀': bits = CHAR_FEMALE
    case '♪': bits = CHAR_NOTE
    case '♫': bits = CHAR_NOTE2
    case '►': bits = CHAR_RIGHT
    case '◄': bits = CHAR_LEFT
    case '↑': bits = CHAR_U_ARROW
    case '↓': bits = CHAR_D_ARROW
    case '→': bits = CHAR_R_ARROW
    case '←': bits = CHAR_L_ARROW
    case '▲': bits = CHAR_UP
    case '▼': bits = CHAR_DOWN
    }
    draw_u128(colorbuffer, bits, x, y, color)
}

draw_ui_area :: proc(drawn_areas: ^Rects, x0, y0, width, height: int) {
    if (drawn_areas.num < len(drawn_areas.rects)) {
        drawn_areas.rects[drawn_areas.num] = Rect{x0, y0, width, height}
        drawn_areas.num += 1
    }
}

draw_int :: proc(ui_layer: ^Ui_Layer, m, x, y: int, color: u32) {
    num_digits := int_digits(m)
    draw_ui_area(ui_layer.drawn_areas, x, y, num_digits * CHAR_WIDTH,  CHAR_HEIGHT)
    for i, n := num_digits, m; n > 0;  {
        draw_digit(ui_layer.colorbuffer, n%10, x + (i-1) * CHAR_WIDTH, y, color)
        n /= 10
        i -= 1
    }
}

draw_string :: proc(ui_layer: ^Ui_Layer, txt: string, x, y: int, color: u32) {
    draw_ui_area(ui_layer.drawn_areas, x, y, len(txt) * CHAR_WIDTH,  CHAR_HEIGHT)
    for c, i in txt {
        if c != ' ' { draw_rune(ui_layer.colorbuffer, c, x + i * CHAR_WIDTH, y, color) }
    }
}
