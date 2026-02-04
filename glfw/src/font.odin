package main
import "core:log"
import "core:math/linalg/glsl"
import gl "vendor:OpenGL"


font_render_u32 :: proc(game: ^Game, x, y, scale: f32, color: glsl.vec3, num: u32) {
    shader_set_vec3(game.sp_font, "font_color", color)
    font_mat: glsl.mat4
    w_size := game.ndc_pixel_w * FONT_WIDTH * scale
    h_size := game.ndc_pixel_h * FONT_HEIGHT * scale
    for i, n := u32_num_digits(num), num; n > 0; {
        font_mat = 1
        font_mat *= glsl.mat4Translate({w_size - 1.0, 1.0 - h_size, 0.0} + {f32(i - 1) * w_size * 2 + x * game.ndc_pixel_w, y * -game.ndc_pixel_h, 0.0})
        font_mat *= glsl.mat4Scale({w_size, h_size, 1.0})
        shader_set_mat4(game.sp_font, "font_mat", font_mat)
        shader_set_int(game.sp_font, "character", i32(16 + n % 10))
        gl.DrawArrays(gl.TRIANGLE_FAN, 0, 4)
        n /= 10
        i -= 1
    }
}


font_render_string :: proc(game: ^Game, x, y, scale: f32, color: glsl.vec3, txt: string) {
    shader_set_vec3(game.sp_font, "font_color", color)
    font_mat: glsl.mat4
    w_size := game.ndc_pixel_w * FONT_WIDTH * scale
    h_size := game.ndc_pixel_h * FONT_HEIGHT * scale
    for r, i in string(txt) {
        if n := (u32(r) < 32 || u32(r) > 127) ? 63 - 32 : u32(r) - 32; n > 0 {
            font_mat = 1
            font_mat *= glsl.mat4Translate({w_size - 1.0, 1.0 - h_size, 0.0} + {f32(i) * w_size * 2 + x * game.ndc_pixel_w * 2, y * -game.ndc_pixel_h * 2, 0.0})
            font_mat *= glsl.mat4Scale({w_size, h_size, 1.0})
            shader_set_mat4(game.sp_font, "font_mat", font_mat)
            shader_set_int(game.sp_font, "character", i32(n))
            gl.DrawArrays(gl.TRIANGLE_FAN, 0, 4)
        }
    }
}
