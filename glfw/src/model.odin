package main
import "core:log"
import "core:math"
import "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import "vendor:glfw"

Model :: struct {
    pos:      glsl.vec2,
    scale:    glsl.vec3,
    rot: glsl.vec3,
    mesh:     ^Mesh,
    color: glsl.vec3,
}

model_render :: proc(model: ^Model, sp: u32, camera: ^Camera, heightmap: []u8) {
    x_min := min(min(camera.pos.x, camera.pos.x + camera.clip_l.x), camera.pos.x + camera.clip_r.x)
    x_max := max(max(camera.pos.x, camera.pos.x + camera.clip_l.x), camera.pos.x + camera.clip_r.x)
    y_min := min(min(camera.pos.y, camera.pos.y + camera.clip_l.y), camera.pos.y + camera.clip_r.y)
    y_max := max(max(camera.pos.y, camera.pos.y + camera.clip_l.y), camera.pos.y + camera.clip_r.y)
    if model.pos.x > x_min && model.pos.x < x_max && model.pos.y > y_min && model.pos.y < y_max {
        z := terrain_height_at(heightmap, model.pos)
        rot_z: glsl.mat4 = 1
        rot_z[0, 0] =  math.cos(model.rot.z); rot_z[0, 1] = -math.sin(model.rot.z)
        rot_z[1, 0] =  math.sin(model.rot.z); rot_z[1, 1] =  math.cos(model.rot.z)
        rot_y: glsl.mat4 = 1
        rot_y[0, 0] =  math.cos(model.rot.y); rot_y[0, 2] =  math.sin(model.rot.y)
        rot_y[2, 0] = -math.sin(model.rot.y); rot_y[2, 2] =  math.cos(model.rot.y)
        rot_x: glsl.mat4 = 1
        rot_x[1, 1] =  math.cos(model.rot.x); rot_x[1, 2] = -math.sin(model.rot.x)
        rot_x[2, 1] =  math.sin(model.rot.x); rot_x[2, 2] =  math.cos(model.rot.x)
        rot_mat := rot_z * rot_y * rot_x
        scale_mat: glsl.mat4 = 1
        scale_mat[0, 0] = model.scale.x * 16.0
        scale_mat[1, 1] = model.scale.y * 16.0
        scale_mat[2, 2] = model.scale.z * 16.0
        trans_mat: glsl.mat4 = 1
        trans_mat[0, 3] = model.pos.x + 8.0
        trans_mat[1, 3] = z + 8
        trans_mat[2, 3] = model.pos.y + 8.0
        model_mat := trans_mat * rot_mat * scale_mat
        shader_set_mat4(sp, "model_mat", model_mat)
        shader_set_mat3(sp, "normal_mat", glsl.mat3(glsl.inverse_transpose(model_mat)));
        shader_set_vec3(sp, "color", model.color)
        gl.BindVertexArray(model.mesh.vao)
        gl.DrawElements(gl.TRIANGLES, model.mesh.num_indices, gl.UNSIGNED_INT, nil)
        gl.BindVertexArray(0)
    }
}
