package main
import "core:os"
import "core:log"
import "core:strings"
import "vendor:cgltf"

gltf_load ::proc(meshes: ^map[string]Mesh, name: string, path: string) {
    cstr_path := strings.clone_to_cstring(path, context.temp_allocator);

    // Load gltf file
    options: cgltf.options
    data, result := cgltf.parse_file(options, cstr_path)
    if result != .success {
        log.errorf("cgltf file parsing failed.")
        os.exit(1)
    }
    
    // Load buffers from gltf file
    result = cgltf.load_buffers(options, data, cstr_path)
    if result != .success {
        log.errorf("cgltf buffer loading failed.")
        os.exit(1)
    }

    // Select mesh and primitive
    mesh := data.meshes[0]
    primitive := mesh.primitives[0]

    // Read indices
    index_accessor := primitive.indices
    num_indices := index_accessor.count
    indices := make([dynamic]u32, num_indices, context.temp_allocator)
    if cgltf.accessor_unpack_indices(index_accessor, raw_data(indices), uint(size_of(u32)), num_indices) < uint(num_indices) {
        log.errorf("cgltf vertex index reading failed.")
        os.exit(1)
    }
    
    // Find vertex position attribute
    pos_accessor: ^cgltf.accessor
    for attrib in primitive.attributes {
        if attrib.type == .position {
            pos_accessor = attrib.data
            break
        }
    }
    if pos_accessor == nil {
        log.errorf("cgltf position attribute not found.")
        os.exit(1)
    }

    // Find vertex normal attribute
    normal_accessor: ^cgltf.accessor
    for attrib in primitive.attributes {
        if attrib.type == .normal {
            normal_accessor = attrib.data
            break
        }
    }
    if normal_accessor == nil {
        log.errorf("cgltf normal attribute not found.")
        os.exit(1)
    }
    
    // Find vertex texture coordinate attribute
    texcoord_accessor: ^cgltf.accessor
    for attrib in primitive.attributes {
        if attrib.type == .texcoord {
            texcoord_accessor = attrib.data
            break
        }
    }
    if texcoord_accessor == nil {
        log.errorf("cgltf texcoord attribute not found.")
        os.exit(1)
    }

    // Read vertices
    num_verts := pos_accessor.count
    verts := make([dynamic]f32, num_verts * 8, context.temp_allocator)
    for i in 0..< num_verts {
        // Read vertex positions
        if !cgltf.accessor_read_float(pos_accessor, i, &verts[i * 8], 3) {
            log.errorf("cgltf vertex position reading failed.")
            os.exit(1)
        }
        // Read vertex normals
        if !cgltf.accessor_read_float(normal_accessor, i, &verts[i * 8 + 3], 3) {
            log.errorf("cgltf vertex normal reading failed.")
            os.exit(1)
        }
        
        // Read vertex texture coordinates
        if i < 10 && !cgltf.accessor_read_float(texcoord_accessor, i, &verts[i * 8 + 3 + 3], 2) {
            log.errorf("cgltf vertex texture coordinates reading failed.")
            os.exit(1)
        } 
        
    }

    // Assign mesh to map of meshes
    meshes[name] = mesh_new(verts[:], indices[:])

    // Free allocated memory
    delete(verts)
    delete(indices)
    cgltf.free(data)
}
