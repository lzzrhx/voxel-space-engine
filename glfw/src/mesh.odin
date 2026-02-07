package main
import gl "vendor:OpenGL"

Mesh :: struct {
    vao: u32,
    vbo: u32,
    ebo: u32,
    num_indices: i32,
}

Primitive :: enum {
    Plane,
    Cube,
}

mesh_new :: proc(verts: []f32, indices: []u32) -> Mesh {
    mesh := Mesh{}
    mesh.num_indices = i32(len(indices))
    gl.GenVertexArrays(1, &mesh.vao)
    gl.BindVertexArray(mesh.vao)
    gl.GenBuffers(1, &mesh.vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(f32) * len(verts), raw_data(verts), gl.STATIC_DRAW)
    gl.GenBuffers(1, &mesh.ebo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.ebo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(f32) * len(indices), raw_data(indices), gl.STATIC_DRAW)
    gl.EnableVertexAttribArray(0)
    gl.EnableVertexAttribArray(1)
    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 0)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 3 * size_of(f32))
    gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 6 * size_of(f32))
    gl.BindVertexArray(0)
    gl.BindBuffer(gl.ARRAY_BUFFER, 0)
    return mesh
}

mesh_destroy :: proc(mesh: ^Mesh) {
    gl.DeleteBuffers(1, &mesh.vbo)
    gl.DeleteBuffers(1, &mesh.ebo)
    gl.DeleteVertexArrays(1, &mesh.vao)
}

mesh_load_primitives :: proc(primitives: ^map[Primitive]Mesh) {
    for primitive in Primitive {
        switch primitive {
            case .Plane:
                verts := [?]f32 {
                    -0.5,  0.0,  0.5, 0.0, 1.0, 0.0, 0.0, 1.0,
                     0.5,  0.0,  0.5, 0.0, 1.0, 0.0, 1.0, 1.0,
                    -0.5,  0.0, -0.5, 0.0, 1.0, 0.0, 0.0, 0.0,
                     0.5,  0.0, -0.5, 0.0, 1.0, 0.0, 1.0, 0.0,
                }
                indices := [?]u32 { 0, 1, 2, 2, 1, 3 }
                primitives[.Plane] = mesh_new(verts[:], indices[:])
            case .Cube:
                verts := [?]f32 {
                    -0.5,  0.5,  0.5,  0.0,  0.0,  1.0, 0.0, 1.0,
                     0.5,  0.5,  0.5,  0.0,  0.0,  1.0, 1.0, 1.0,
                    -0.5, -0.5,  0.5,  0.0,  0.0,  1.0, 0.0, 0.0,
                     0.5, -0.5,  0.5,  0.0,  0.0,  1.0, 1.0, 0.0,
                     0.5,  0.5, -0.5,  0.0,  0.0, -1.0, 0.0, 1.0,
                    -0.5,  0.5, -0.5,  0.0,  0.0, -1.0, 1.0, 1.0,
                     0.5, -0.5, -0.5,  0.0,  0.0, -1.0, 0.0, 0.0,
                    -0.5, -0.5, -0.5,  0.0,  0.0, -1.0, 1.0, 0.0,
                    -0.5,  0.5, -0.5, -1.0,  0.0,  0.0, 0.0, 1.0,
                    -0.5,  0.5,  0.5, -1.0,  0.0,  0.0, 1.0, 1.0,
                    -0.5, -0.5, -0.5, -1.0,  0.0,  0.0, 0.0, 0.0,
                    -0.5, -0.5,  0.5, -1.0,  0.0,  0.0, 1.0, 0.0,
                     0.5,  0.5,  0.5,  1.0,  0.0,  0.0, 0.0, 1.0,
                     0.5,  0.5, -0.5,  1.0,  0.0,  0.0, 1.0, 1.0,
                     0.5, -0.5,  0.5,  1.0,  0.0,  0.0, 0.0, 0.0,
                     0.5, -0.5, -0.5,  1.0,  0.0,  0.0, 1.0, 0.0,
                    -0.5,  0.5, -0.5,  0.0,  1.0,  0.0, 0.0, 1.0,
                     0.5,  0.5, -0.5,  0.0,  1.0,  0.0, 1.0, 1.0,
                    -0.5,  0.5,  0.5,  0.0,  1.0,  0.0, 0.0, 0.0,
                     0.5,  0.5,  0.5,  0.0,  1.0,  0.0, 1.0, 0.0,
                    -0.5, -0.5,  0.5,  0.0, -1.0,  0.0, 0.0, 1.0,
                     0.5, -0.5,  0.5,  0.0, -1.0,  0.0, 1.0, 1.0,
                    -0.5, -0.5, -0.5,  0.0, -1.0,  0.0, 0.0, 0.0,
                     0.5, -0.5, -0.5,  0.0, -1.0,  0.0, 1.0, 0.0,
                }
                indices := [?]u32 { 0,  2,  1, 1,  2,  3, 4,  6,  5, 5,  6,  7, 8, 10,  9, 9, 10, 11, 12, 14, 13, 13, 14, 15, 16, 18, 17, 17, 18, 19, 20, 22, 21, 21, 22, 23 }
                primitives[.Cube] = mesh_new(verts[:], indices[:])
        }
    }
}
