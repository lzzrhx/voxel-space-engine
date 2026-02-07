package main
import "core:fmt"
import "core:strings"
import gl "vendor:OpenGL"
import "core:math/linalg/glsl"

DirLight :: struct {
    dir:         glsl.vec3,
    diffuse:     glsl.vec3,
    specular:    glsl.vec3,
}

Light :: struct {
    pos:         glsl.vec3,
    diffuse:     glsl.vec3,
    specular:    glsl.vec3,
    constant:    f32,
    linear:      f32,
    quadratic:   f32,
    scale:       glsl.vec3,
    mesh:        ^Mesh,
    u_name_pos: cstring,
    u_name_diffuse: cstring,
    u_name_specular: cstring,
    u_name_constant: cstring,
    u_name_linear: cstring,
    u_name_quadratic: cstring,
}

light_add :: proc(lights: ^[MAX_NUM_LIGHTS]Light, num: ^u32, pos, diffuse, specular: glsl.vec3, constant, linear, quadratic: f32, mesh: ^Mesh, scale: glsl.vec3 = {1.0, 1.0, 1.0}) {
    lights[num^] = Light{ pos = pos, diffuse = diffuse, specular = specular, constant = constant, linear = linear, quadratic = quadratic, mesh = mesh, scale = scale,
        u_name_pos = strings.clone_to_cstring(fmt.tprintf("lights[%d].pos", num^)),
        u_name_diffuse = strings.clone_to_cstring(fmt.tprintf("lights[%d].diffuse", num^)),
        u_name_specular = strings.clone_to_cstring(fmt.tprintf("lights[%d].specular", num^)),
        u_name_constant = strings.clone_to_cstring(fmt.tprintf("lights[%d].constant", num^)),
        u_name_linear = strings.clone_to_cstring(fmt.tprintf("lights[%d].linear", num^)),
        u_name_quadratic = strings.clone_to_cstring(fmt.tprintf("lights[%d].quadratic", num^)),
    }
    num^ += 1
}

light_destroy :: proc(light: ^Light) {
    delete(light.u_name_pos)
    delete(light.u_name_diffuse)
    delete(light.u_name_specular)
    delete(light.u_name_constant)
    delete(light.u_name_linear)
    delete(light.u_name_quadratic)
}

light_render :: proc(light: ^Light, shader_program: u32) {
    shader_set_mat4(shader_program, "model_mat", glsl.mat4Translate(light.pos) * glsl.mat4Scale(light.scale))
    shader_set_vec3(shader_program, "diffuse", light.diffuse)
    shader_set_vec3(shader_program, "specular", light.specular)
    gl.BindVertexArray(light.mesh.vao)
    gl.DrawElements(gl.TRIANGLES, light.mesh.num_indices, gl.UNSIGNED_INT, nil)
    gl.BindVertexArray(0)
}

