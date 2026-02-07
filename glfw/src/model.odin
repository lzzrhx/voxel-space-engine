package main
import "core:math"
import "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import "vendor:glfw"

Model :: struct {
    pos:      glsl.vec3,
    scale:    glsl.vec3,
    rot: glsl.vec3,
    mesh:     ^Mesh,
    material: ^Material,
}

Material :: struct {
    shininess: f32,
    color: glsl.vec3,
}

model_render :: proc(model: ^Model, sp: u32) {
    rot_z: glsl.mat4 = 1
    rot_z[0, 0] =  math.cos(model.rot.z); rot_z[0, 1] = -math.sin(model.rot.z)
    rot_z[1, 0] =  math.sin(model.rot.z); rot_z[1, 1] =  math.cos(model.rot.z)
    rot_y: glsl.mat4 = 1
    rot_y[0, 0] =  math.cos(model.rot.y); rot_y[0, 2] =  math.sin(model.rot.y)
    rot_y[2, 0] = -math.sin(model.rot.y); rot_y[2, 2] =  math.cos(model.rot.y)
    rot_x: glsl.mat4 = 1
    rot_x[1, 1] =  math.cos(model.rot.x); rot_x[1, 2] = -math.sin(model.rot.x)
    rot_x[2, 1] =  math.sin(model.rot.x); rot_x[2, 2] =  math.cos(model.rot.x)
    model_mat := glsl.mat4Translate(model.pos) * rot_z * rot_y * rot_x * glsl.mat4Scale(model.scale)
    shader_set_mat4(sp, "model_mat", model_mat)
    shader_set_mat3(sp, "normal_mat", glsl.mat3(glsl.inverse_transpose(model_mat)));
    shader_set_float(sp, "material.shininess", model.material.shininess)
    shader_set_vec3(sp, "material.color", model.material.color)
    gl.BindVertexArray(model.mesh.vao)
    gl.DrawElements(gl.TRIANGLES, model.mesh.num_indices, gl.UNSIGNED_INT, nil)
    gl.BindVertexArray(0)
}

