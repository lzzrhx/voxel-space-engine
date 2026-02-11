package main
import "core:fmt"
import "core:strings"
import gl "vendor:OpenGL"
import "core:math/linalg/glsl"
import "core:math"

DirLight :: struct {
    dir:   glsl.vec3,
    color: glsl.vec3,
}

Light :: struct {
    pos:              glsl.vec2,
    color:            glsl.vec3,
    constant:         f32,
    linear:           f32,
    quadratic:        f32,
    scale:            glsl.vec3,
    mesh:             ^Mesh,
    u_name_pos:       cstring,
    u_name_color:     cstring,
    u_name_constant:  cstring,
    u_name_linear:    cstring,
    u_name_quadratic: cstring,
}

light_add :: proc(lights: ^[MAX_NUM_LIGHTS]Light, num: ^u32, pos: glsl.vec2, color: glsl.vec3, constant, linear, quadratic: f32, mesh: ^Mesh, scale: glsl.vec3 = {1.0, 1.0, 1.0}) {
    lights[num^] = Light{ pos = pos, color = color, constant = constant, linear = linear, quadratic = quadratic, mesh = mesh, scale = scale,
        u_name_pos = strings.clone_to_cstring(fmt.tprintf("lights[%d].pos", num^)),
        u_name_color = strings.clone_to_cstring(fmt.tprintf("lights[%d].color", num^)),
        u_name_constant = strings.clone_to_cstring(fmt.tprintf("lights[%d].constant", num^)),
        u_name_linear = strings.clone_to_cstring(fmt.tprintf("lights[%d].linear", num^)),
        u_name_quadratic = strings.clone_to_cstring(fmt.tprintf("lights[%d].quadratic", num^)),
    }
    num^ += 1
}

light_destroy :: proc(light: ^Light) {
    delete(light.u_name_pos)
    delete(light.u_name_color)
    delete(light.u_name_constant)
    delete(light.u_name_linear)
    delete(light.u_name_quadratic)
}

light_render :: proc(light: ^Light, sp: u32, camera: ^Camera, heightmap: []u8) {
    x_min := min(min(camera.pos.x, camera.pos.x + camera.clip_l.x), camera.pos.x + camera.clip_r.x)
    x_max := max(max(camera.pos.x, camera.pos.x + camera.clip_l.x), camera.pos.x + camera.clip_r.x)
    y_min := min(min(camera.pos.y, camera.pos.y + camera.clip_l.y), camera.pos.y + camera.clip_r.y)
    y_max := max(max(camera.pos.y, camera.pos.y + camera.clip_l.y), camera.pos.y + camera.clip_r.y)
    if light.pos.x > x_min && light.pos.x < x_max && light.pos.y > y_min && light.pos.y < y_max {
        z := terrain_height_at(heightmap, light.pos)
        scale_mat: glsl.mat4 = 1
        scale_mat[0, 0] = light.scale.x * 16.0
        scale_mat[1, 1] = light.scale.y * 16.0
        scale_mat[2, 2] = light.scale.z * 16.0
        trans_mat: glsl.mat4 = 1
        trans_mat[0, 3] = light.pos.x + 8.0
        trans_mat[1, 3] = z + 8
        trans_mat[2, 3] = light.pos.y + 8.0
        model_mat := trans_mat * scale_mat
        shader_set_mat4(sp, "model_mat", model_mat)
        shader_set_vec3(sp, "color", light.color)
        gl.BindVertexArray(light.mesh.vao)
        gl.DrawElements(gl.TRIANGLES, light.mesh.num_indices, gl.UNSIGNED_INT, nil)
        gl.BindVertexArray(0)
    }
}
