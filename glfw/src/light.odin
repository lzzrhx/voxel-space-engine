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
/*
light_render :: proc(light: ^Light, shader_program: u32) {
    shader_set_mat4(shader_program, "model_mat", glsl.mat4Translate(light.pos) * glsl.mat4Scale(light.scale))
    shader_set_vec3(shader_program, "diffuse", light.diffuse)
    shader_set_vec3(shader_program, "specular", light.specular)
    gl.BindVertexArray(light.mesh.vao)
    gl.DrawElements(gl.TRIANGLES, light.mesh.num_indices, gl.UNSIGNED_INT, nil)
    gl.BindVertexArray(0)
}
*/

light_render :: proc(light: ^Light, sp: u32, camera: ^Camera, window_world_ratio: glsl.vec2) {
    x_min := min(min(camera.pos.x, camera.pos.x + camera.clip_l.x), camera.pos.x + camera.clip_r.x)
    x_max := max(max(camera.pos.x, camera.pos.x + camera.clip_r.x), camera.pos.x + camera.clip_r.x)
    y_min := min(min(camera.pos.y, camera.pos.y + camera.clip_l.y), camera.pos.y + camera.clip_r.y)
    y_max := max(max(camera.pos.y, camera.pos.y + camera.clip_l.y), camera.pos.y + camera.clip_r.y)
    if light.pos.x > x_min && light.pos.x < x_max && light.pos.y > y_min && light.pos.y < y_max {
        if depth := dot2(light.pos.x - camera.pos.x, light.pos.y - camera.pos.y, camera.clip_l.x + camera.clip_r.x, camera.clip_l.y + camera.clip_r.y) / mag2(camera.clip_l.x + camera.clip_r.x, camera.clip_l.y + camera.clip_r.y); depth > 1.0 {
            depth_scale := WORLD_RENDER_WIDTH * MODEL_TERRAIN_SCALE / depth
            terrain_height: f32 = 20.0 // TODO: get height from texxture
            ndc_pos: glsl.vec3 = {
                f32(math.round_f32((WORLD_RENDER_WIDTH * (CAM_CLIP * (light.pos.x - camera.pos.x) - depth * camera.clip_l.x)) / (depth * (camera.clip_r.x - camera.clip_l.x))) * window_world_ratio.x / WINDOW_WIDTH * 2.0 - 1.0),
                f32((math.round_f32((camera.z - terrain_height) / depth * TERRAIN_SCALE + camera.rot.x) * window_world_ratio.y / WINDOW_HEIGHT * 2.0 - 1.0) * -1 + depth_scale * 0.5),
                depth / CAM_CLIP
            }
            model_mat := glsl.mat4Translate(ndc_pos) * glsl.mat4Scale(light.scale) * glsl.mat4Scale(depth_scale)
            shader_set_float(sp, "depth", ndc_pos.z)
            shader_set_mat4(sp, "model_mat", model_mat)
            shader_set_mat3(sp, "normal_mat", glsl.mat3(glsl.inverse_transpose(model_mat)));
            shader_set_vec3(sp, "color", light.color)
            shader_set_vec2(sp, "world_pos", light.pos)
            gl.BindVertexArray(light.mesh.vao)
            gl.DrawElements(gl.TRIANGLES, light.mesh.num_indices, gl.UNSIGNED_INT, nil)
            gl.BindVertexArray(0)
        }
    }
}

