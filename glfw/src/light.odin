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

light_render :: proc(light: ^Light, sp: u32, camera: ^Camera, window_world_ratio: glsl.vec2, terrain_height: []u8) {
    x_min := min(min(camera.pos.x, camera.pos.x + camera.clip_l.x), camera.pos.x + camera.clip_r.x)
    x_max := max(max(camera.pos.x, camera.pos.x + camera.clip_r.x), camera.pos.x + camera.clip_r.x)
    y_min := min(min(camera.pos.y, camera.pos.y + camera.clip_l.y), camera.pos.y + camera.clip_r.y)
    y_max := max(max(camera.pos.y, camera.pos.y + camera.clip_l.y), camera.pos.y + camera.clip_r.y)
    if light.pos.x > x_min && light.pos.x < x_max && light.pos.y > y_min && light.pos.y < y_max {
        if depth := dot2(light.pos.x - camera.pos.x, light.pos.y - camera.pos.y, camera.clip_l.x + camera.clip_r.x, camera.clip_l.y + camera.clip_r.y) / mag2(camera.clip_l.x + camera.clip_r.x, camera.clip_l.y + camera.clip_r.y); depth > 1.0 {
            depth_scale := WORLD_RENDER_WIDTH * MODEL_TERRAIN_SCALE / depth
            z := f32(terrain_height_at(terrain_height, light.pos)) * 2
            ndc_pos: glsl.vec3 = {
                f32(math.round_f32((WORLD_RENDER_WIDTH * (CAM_CLIP * (light.pos.x - camera.pos.x) - depth * camera.clip_l.x)) / (depth * (camera.clip_r.x - camera.clip_l.x))) * window_world_ratio.x / WINDOW_WIDTH * 2.0 - 1.0),
                f32((math.round_f32((camera.z - z) / depth * TERRAIN_SCALE + camera.rot.x) * window_world_ratio.y / WINDOW_HEIGHT * 2.0 - 1.0) * -1 + depth_scale * 0.5),
                depth / CAM_CLIP
            }
            aspect := f32(WINDOW_HEIGHT) / f32(WINDOW_WIDTH)
            ndc_mat: glsl.mat4 = 1
            ndc_mat[0, 0] = aspect
            ndc_mat[0, 3] = ndc_pos.x
            ndc_mat[1, 3] = ndc_pos.y
            ndc_mat[2, 3] = ndc_pos.z
            cam_pos := glsl.vec3{camera.pos.x, camera.z, camera.pos.y}
            cam_dir := glsl.normalize(glsl.vec3{camera.target.x, 0.0, camera.target.y} - cam_pos)
            cam_right := glsl.normalize(glsl.cross_vec3({0.0, 1.0, 0.0}, cam_dir))
            cam_up := glsl.cross_vec3(cam_dir, cam_right)
            look_at: glsl.mat4 = 1
            look_at[0, 0] = -cam_right.x
            look_at[0, 1] = -cam_right.y
            look_at[0, 2] = -cam_right.z
            look_at[1, 0] = cam_up.x
            look_at[1, 1] = cam_up.y
            look_at[1, 2] = cam_up.z
            look_at[2, 0] = cam_dir.x
            look_at[2, 1] = cam_dir.y
            look_at[2, 2] = cam_dir.z
            model_mat := ndc_mat * look_at * glsl.mat4Scale(light.scale) * glsl.mat4Scale(depth_scale)
            normal_mat := ndc_mat * glsl.mat4Scale(light.scale) * glsl.mat4Scale(depth_scale)
            shader_set_float(sp, "depth", ndc_pos.z)
            shader_set_mat4(sp, "model_mat", model_mat)
            shader_set_mat3(sp, "normal_mat", glsl.mat3(glsl.inverse_transpose(normal_mat)));
            shader_set_vec3(sp, "color", light.color)
            shader_set_vec2(sp, "world_pos", light.pos)
            gl.BindVertexArray(light.mesh.vao)
            gl.DrawElements(gl.TRIANGLES, light.mesh.num_indices, gl.UNSIGNED_INT, nil)
            gl.BindVertexArray(0)
        }
    }
}

