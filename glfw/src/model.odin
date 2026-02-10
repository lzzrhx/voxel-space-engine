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

model_render :: proc(model: ^Model, sp: u32, camera: ^Camera, window_world_ratio: glsl.vec2, terrain_height: []u8) {
    x_min := min(min(camera.pos.x, camera.pos.x + camera.clip_l.x), camera.pos.x + camera.clip_r.x)
    x_max := max(max(camera.pos.x, camera.pos.x + camera.clip_l.x), camera.pos.x + camera.clip_r.x)
    y_min := min(min(camera.pos.y, camera.pos.y + camera.clip_l.y), camera.pos.y + camera.clip_r.y)
    y_max := max(max(camera.pos.y, camera.pos.y + camera.clip_l.y), camera.pos.y + camera.clip_r.y)
    if model.pos.x > x_min && model.pos.x < x_max && model.pos.y > y_min && model.pos.y < y_max {
        if depth := dot2(model.pos.x - camera.pos.x, model.pos.y - camera.pos.y, camera.clip_l.x + camera.clip_r.x, camera.clip_l.y + camera.clip_r.y) / mag2(camera.clip_l.x + camera.clip_r.x, camera.clip_l.y + camera.clip_r.y); depth > 1.0 {
            depth_scale := WORLD_RENDER_WIDTH * MODEL_TERRAIN_SCALE / depth
            z := f32(terrain_height_at(terrain_height, model.pos)) + TILE_SIZE * 2.0
            ndc_pos: glsl.vec3 = {
                f32(math.round_f32((WORLD_RENDER_WIDTH * (CAM_CLIP * (model.pos.x - camera.pos.x) - depth * camera.clip_l.x)) / (depth * (camera.clip_r.x - camera.clip_l.x))) * window_world_ratio.x / WINDOW_WIDTH * 2.0 - 1.0),
                f32((math.round_f32((camera.z - z) / depth * TERRAIN_SCALE + camera.rot.x) * window_world_ratio.y / WINDOW_HEIGHT * 2.0 - 1.0) * -1),
                depth / CAM_CLIP
            }
            aspect := f32(WINDOW_HEIGHT) / f32(WINDOW_WIDTH)
            ndc_mat: glsl.mat4 = 1
            ndc_mat[0, 0] = aspect
            ndc_mat[0, 3] = ndc_pos.x
            ndc_mat[1, 3] = ndc_pos.y
            ndc_mat[2, 3] = ndc_pos.z
            //fov := 1.0 / math.tan_f32(glsl.radians_f32(45.0)/2.0)
            //ndc_mat[0, 0] = aspect * fov
            //ndc_mat[1, 1] = fov
            //ndc_mat[3, 2] = 1
            cam_pos := glsl.vec3{camera.pos.x, camera.z * 0.5, camera.pos.y}
            cam_dir := glsl.normalize(glsl.vec3{camera.target.x, z, camera.target.y} - cam_pos)
            cam_right := glsl.normalize(glsl.cross_vec3({0.0, 1.0, 0.0}, cam_dir))
            cam_up := glsl.cross_vec3(cam_dir, cam_right)
            view_mat: glsl.mat4 = 1
            view_mat[0, 0] = -cam_right.x
            view_mat[0, 1] = -cam_right.y
            view_mat[0, 2] = -cam_right.z
            view_mat[1, 0] = cam_up.x
            view_mat[1, 1] = cam_up.y
            view_mat[1, 2] = cam_up.z
            view_mat[2, 0] = cam_dir.x
            view_mat[2, 1] = cam_dir.y
            view_mat[2, 2] = cam_dir.z
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
            scale_mat[0, 0] = model.scale.x * depth_scale
            scale_mat[1, 1] = model.scale.y * depth_scale
            scale_mat[2, 2] = model.scale.z * depth_scale
            shader_set_float(sp, "depth", ndc_pos.z)
            shader_set_mat4(sp, "ndc_mat", ndc_mat)
            shader_set_mat4(sp, "model_mat", view_mat * rot_mat * scale_mat)
            shader_set_mat3(sp, "normal_mat", glsl.mat3(glsl.inverse_transpose(rot_mat * scale_mat)));
            shader_set_vec3(sp, "color", model.color)
            shader_set_vec2(sp, "world_pos", model.pos)
            gl.BindVertexArray(model.mesh.vao)
            gl.DrawElements(gl.TRIANGLES, model.mesh.num_indices, gl.UNSIGNED_INT, nil)
            gl.BindVertexArray(0)
        }
    }
}

