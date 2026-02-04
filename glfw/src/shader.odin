package main
import "core:log"
import "core:os"
import gl "vendor:OpenGL"
import "core:math/linalg/glsl"

shader_load_file :: proc(path: string, type: gl.Shader_Type) -> u32 {
    data: []u8
    ok: bool
    data, ok = os.read_entire_file(path)
    if !ok {
        log.errorf("File reading failed. (%s)", path)
        os.exit(1)
    }
    defer delete(data)
    id : u32
    id, ok = gl.compile_shader_from_source(string(data), type)
    if !ok {
        log.errorf("Shader compilation failed. (%s)", path)
        os.exit(1)
    }
    return id
}

shader_load_vs_fs :: proc(sp: ^u32, vs, fs: string) {
    ok : bool
    sp^, ok = gl.load_shaders_file(vs, fs)
    if !ok {
        log.errorf("Shader loading failed. (%s %s)", vs, fs)
        os.exit(1)
    }
}

shader_load_vs_gs_fs :: proc(sp: ^u32, vs, gs, fs: string) {
    ok: bool
    vs_id := shader_load_file(vs, .VERTEX_SHADER)
    defer gl.DeleteShader(vs_id)
    gs_id := shader_load_file(gs, .GEOMETRY_SHADER)
    defer gl.DeleteShader(gs_id)
    fs_id := shader_load_file(fs, .FRAGMENT_SHADER)
    defer gl.DeleteShader(fs_id)
    sp^, ok = gl.create_and_link_program([]u32{vs_id, gs_id, fs_id})
    if !ok {
        log.errorf("Shader program creation failed. (%s %s %s)", vs, gs, fs)
        os.exit(1)
    }
}
shader_load_cs :: proc(sp: ^u32, cs: string) {
    ok: bool
    sp^, ok = gl.load_compute_file(cs)
    if !ok {
        log.errorf("Shader loading failed (%s).", cs)
        os.exit(1)
    }
}

shader_set_bool :: proc(id: u32, name: cstring, value: bool) {
    gl.Uniform1i(gl.GetUniformLocation(id, name), i32(value))
}

shader_set_int :: proc(id: u32, name: cstring, value: i32) {
    gl.Uniform1i(gl.GetUniformLocation(id, name), value)
}

shader_set_uint :: proc(id: u32, name: cstring, value: u32) {
    gl.Uniform1ui(gl.GetUniformLocation(id, name), value)
}

shader_set_float :: proc(id: u32, name: cstring, value: f32) {
    gl.Uniform1f(gl.GetUniformLocation(id, name), value)
}

shader_set_vec2_v :: proc(id: u32, name: cstring, value: glsl.vec2) {
    lc := value
    gl.Uniform2fv(gl.GetUniformLocation(id, name), 1, raw_data(&lc))
}

shader_set_vec2_f :: proc(id: u32, name: cstring, x, y: f32) {
    gl.Uniform2f(gl.GetUniformLocation(id, name), x, y)
}

shader_set_vec2 :: proc {
    shader_set_vec2_v,
    shader_set_vec2_f,
}

shader_set_vec3_v :: proc(id: u32, name: cstring, value: glsl.vec3) {
    lc := value
    gl.Uniform3fv(gl.GetUniformLocation(id, name), 1, raw_data(&lc))
}

shader_set_vec3_f :: proc(id: u32, name: cstring, x, y, z: f32) {
    gl.Uniform3f(gl.GetUniformLocation(id, name), x, y, z)
}

shader_set_vec3 :: proc {
    shader_set_vec3_v,
    shader_set_vec3_f,
}

shader_set_vec4_v :: proc(id: u32, name: cstring, value: glsl.vec4) {
    lc := value
    gl.Uniform4fv(gl.GetUniformLocation(id, name), 1, raw_data(&lc))
}

shader_set_vec4_f :: proc(id: u32, name: cstring, x, y, z, w: f32) {
    gl.Uniform4f(gl.GetUniformLocation(id, name), x, y, z, w)
}

shader_set_vec4 :: proc {
    shader_set_vec4_v,
    shader_set_vec4_f,
}

shader_set_mat2 :: proc(id: u32, name: cstring, mat: glsl.mat2) {
    lc := mat
    gl.UniformMatrix2fv(gl.GetUniformLocation(id, name), 1, gl.FALSE, raw_data(&lc))
}

shader_set_mat3 :: proc(id: u32, name: cstring, mat: glsl.mat3) {
    lc := mat
    gl.UniformMatrix3fv(gl.GetUniformLocation(id, name), 1, gl.FALSE, raw_data(&lc))
}

shader_set_mat4 :: proc(id: u32, name: cstring, mat: glsl.mat4) {
    lc := mat
    gl.UniformMatrix4fv(gl.GetUniformLocation(id, name), 1, gl.FALSE, raw_data(&lc))
}
