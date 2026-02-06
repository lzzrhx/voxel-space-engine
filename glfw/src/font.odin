package main
import "core:log"
import "core:math/linalg/glsl"
import gl "vendor:OpenGL"

font_render_u32 :: proc(game: ^Game, x, y, scale: f32, color: glsl.vec3, num: u32) {
    shader_set_vec3(game.sp_font, "color", color)
    shader_set_float(game.sp_font, "scale", scale)
    shader_set_vec2_f(game.sp_font, "pos", x, y)
    count := u32_num_digits(num)
    for i, n := count - 1, num; n > 0; i-= 1 {
        game.font_chars[i] = 16 + n % 10
        n /= 10
    }
    if (count > 0) {
        gl.BufferSubData(gl.ARRAY_BUFFER, 0, int(count) * size_of(u32), raw_data(game.font_chars))
        gl.DrawArraysInstanced(gl.TRIANGLE_FAN, 0, 4, i32(count))
    }
}

font_render_string :: proc(game: ^Game, x, y, scale: f32, color: glsl.vec3, txt: string) {
    shader_set_vec3(game.sp_font, "color", color)
    shader_set_float(game.sp_font, "scale", scale)
    shader_set_vec2_f(game.sp_font, "pos", x, y)
    count := 0
    for r, i in string(txt) {
        if n := (u32(r) < 32 || u32(r) > 127) ? 63 - 32 : u32(r) - 32; n > 0 && count < FONT_MAX_CHARS {
            game.font_chars[count] = n
            count += 1;
        }
    }
    if (count > 0) {
        gl.BufferSubData(gl.ARRAY_BUFFER, 0, count * size_of(u32), raw_data(game.font_chars))
        gl.DrawArraysInstanced(gl.TRIANGLE_FAN, 0, 4, i32(count))
    }
}
