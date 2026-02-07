package main
import "core:log"
import "core:math/linalg/glsl"
import gl "vendor:OpenGL"

font_render :: proc {
    font_render_u32,
    font_render_string,
}

font_render_u32 :: proc(game: ^Game, x, y: f32, num: u32, scale: f32 = 1.0, color: glsl.vec3 = {1.0, 1.0, 1.0}) {
    count := u32_num_digits(num)
    for i, n := count - 1, num; n > 0; i-= 1 {
        game.font_chars[i] = (16 + n % 10) | (i << 16)
        n /= 10
    }
    if (count > 0) { font_draw_call(game, count, x, y, scale, color) }
}

font_render_string :: proc(game: ^Game, x, y: f32, txt: string, scale: f32 = 1.0, color: glsl.vec3 = {1.0, 1.0, 1.0}) {
    count: u32
    col: u32
    line: u32
    prev: rune
    for r, i in string(txt) {
        if u32(r) == 10 {
            line += 1
            col = 0
        } else if n := (u32(r) < 32 || u32(r) > 127) ? 63 - 32 : u32(r) - 32; count < FONT_MAX_CHARS {
            if r == 'n' && prev == '\\' {
                line += 1
                col = 0
                count -= 1
            } else {
                game.font_chars[count] = n | (line << 8) | (col << 16)
                col +=1
                count += 1
            }
            prev = r
        }
    }
    if (count > 0) { font_draw_call(game, count, x, y, scale, color) }
}

font_draw_call :: proc(game: ^Game, count: u32, x, y, scale: f32, color: glsl.vec3) {
    shader_set_vec3(game.sp_font, "color", color)
    shader_set_float(game.sp_font, "scale", scale)
    shader_set_vec2_f(game.sp_font, "pos", x, y)
    gl.BufferSubData(gl.ARRAY_BUFFER, 0, int(count) * size_of(u32), raw_data(game.font_chars))
    gl.DrawArraysInstanced(gl.TRIANGLE_FAN, 0, 4, i32(count))
}
