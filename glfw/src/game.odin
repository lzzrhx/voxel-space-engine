package main
import "core:fmt"
import "core:strings"
import "core:os"
import "core:image"
import "core:log"
import "core:math"
import "vendor:glfw"
import "core:math/linalg/glsl"
import gl "vendor:OpenGL"

Game :: struct {
    window:             glfw.WindowHandle,
    ndc_pixel:          glsl.vec2,
    window_world_ratio: glsl.vec2,
    frame:              u32,
    fps_frame:          u32,
    time:               f64,
    prev_time:          f64,
    fps:                u32,
    vao:                u32,
    vbo:                u32,
    dt:                 f64,
    sp_terrain:         u32,
    sp_screen:          u32,
    sp_font:            u32,
    sp_solid:           u32,
    sp_light:           u32,
    sp_grid:            u32,
    sp_gizmo:           u32,
    font_tex:           u32,
    font_vao:           u32,
    font_vbo:           u32,
    font_chars:         ^[FONT_MAX_CHARS]u32,
    terrain_colorbuf:   u32,
    terrain_depthbuf:   u32,
    terrain_color_tex:  u32,
    terrain_height_tex: u32,
    terrain_height:     ^[TERRAIN_SIZE * TERRAIN_SIZE]u8,
    camera:             ^Camera,
    primitives:         map[Primitive]Mesh,
    meshes:             map[string]Mesh,
    models:             [dynamic]Model,
    num_lights:         u32,
    ambient_light:      glsl.vec3,
    dir_light:          ^DirLight,
    lights:             ^[MAX_NUM_LIGHTS]Light,
}

gl_check_error :: proc(location := #caller_location) {
    if err := gl.GetError(); err != gl.NO_ERROR {
        log.errorf("OpenGL error! %s", gl.GL_Enum(err), location = location)
    }
}

game_init :: proc(game: ^Game) {
    // GLFW and OpenGL initialization
    glfw.Init()
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_VERSION_MAJOR)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_VERSION_MINOR)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    if OPTION_ANTI_ALIAS { glfw.WindowHint(glfw.SAMPLES, 4) }
    game.window = glfw.CreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE, nil, nil)
    if game.window == nil {
        log.errorf("GLFW window creation failed.")
        glfw.Terminate()
        os.exit(1)
    }
    glfw.MakeContextCurrent(game.window)
    if !OPTION_VSYNC { glfw.SwapInterval(0) }
    gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, glfw.gl_set_proc_address)
    gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
    game.ndc_pixel = {2.0 / WINDOW_WIDTH, 2.0 / WINDOW_HEIGHT}
    game.window_world_ratio = {WINDOW_WIDTH/WORLD_RENDER_WIDTH, WINDOW_HEIGHT/WORLD_RENDER_HEIGHT}
    
    // OpenGL settings
    gl.Enable(gl.CULL_FACE)
    gl.Enable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
    if OPTION_GAMMA_CORRECTION { gl.Enable(gl.FRAMEBUFFER_SRGB) }
    if OPTION_ANTI_ALIAS { gl.Enable(gl.MULTISAMPLE) }

    // Vertex array object & vertex buffer object setup
    gl.GenVertexArrays(1, &game.vao)
    gl.BindVertexArray(game.vao)
    gl.GenBuffers(1, &game.vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, game.vbo)

    // Load shaders
    shader_load_vs_fs(&game.sp_font, SHADER_FONT_VERT, SHADER_FONT_FRAG)
    shader_load_vs_fs(&game.sp_screen, SHADER_SCREEN_VERT, SHADER_SCREEN_FRAG)
    shader_load_vs_fs(&game.sp_solid, SHADER_SOLID_VERT, SHADER_SOLID_FRAG)
    shader_load_vs_fs(&game.sp_light, SHADER_LIGHT_VERT, SHADER_LIGHT_FRAG)
    shader_load_vs_fs(&game.sp_grid, SHADER_GRID_VERT, SHADER_GRID_FRAG)
    shader_load_vs_fs(&game.sp_gizmo, SHADER_GIZMO_VERT, SHADER_GIZMO_FRAG)
    shader_load_cs(&game.sp_terrain, SHADER_TERRAIN)

    // Terrain colorbuffer setup
    gl.GenTextures(1, &game.terrain_colorbuf)
    gl.ActiveTexture(gl.TEXTURE1)
    gl.BindTexture(gl.TEXTURE_2D, game.terrain_colorbuf)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA32F, WORLD_RENDER_WIDTH, WORLD_RENDER_HEIGHT, 0, gl.RGBA, gl.UNSIGNED_BYTE, nil)
    gl.BindImageTexture(0, game.terrain_colorbuf, 0, gl.FALSE, 0, gl.READ_ONLY, gl.RGBA32F)
    gl.UseProgram(game.sp_screen)
    shader_set_int(game.sp_screen, "terrain_colorbuf", 1)
    
    // Terrain depthbuffer setup
    gl.GenTextures(1, &game.terrain_depthbuf)
    gl.ActiveTexture(gl.TEXTURE2)
    gl.BindTexture(gl.TEXTURE_2D, game.terrain_depthbuf)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.R32F, WORLD_RENDER_WIDTH, WORLD_RENDER_HEIGHT, 0, gl.RED, gl.UNSIGNED_BYTE, nil)
    gl.BindImageTexture(1, game.terrain_depthbuf, 0, gl.FALSE, 0, gl.READ_ONLY, gl.R32F)
    gl.UseProgram(game.sp_screen)
    shader_set_int(game.sp_screen, "terrain_depthbuf", 2)

    // Font setup
    game.font_chars = new([FONT_MAX_CHARS]u32)
    game.font_tex = texture_load(FONT_PATH, filtering = false)
    gl.ActiveTexture(gl.TEXTURE3)
    gl.BindTexture(gl.TEXTURE_2D, game.font_tex)
    gl.GenVertexArrays(1, &game.font_vao)
    gl.BindVertexArray(game.font_vao)
    gl.GenBuffers(1, &game.font_vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, game.font_vbo)
    gl.BufferData(gl.ARRAY_BUFFER, FONT_MAX_CHARS * size_of(u32), raw_data(game.font_chars), gl.STATIC_DRAW)
    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 1, gl.FLOAT, gl.FALSE, size_of(u32), 0)
    gl.VertexAttribIPointer(0, 1, gl.UNSIGNED_INT, size_of(u32), 0)
    gl.VertexAttribDivisor(0, 1)
    gl.BindVertexArray(0)
    gl.BindBuffer(gl.ARRAY_BUFFER, 0)
    gl.UseProgram(game.sp_font)
    shader_set_float(game.sp_font, "spacing", FONT_SPACING)
    shader_set_vec2(game.sp_font, "ndc_pixel", game.ndc_pixel)
    shader_set_vec2(game.sp_font, "size", {FONT_WIDTH, FONT_HEIGHT})
    shader_set_int(game.sp_font, "font_tex", 3)
    
    // Load terrain and setup terrain shader
    game.terrain_color_tex = texture_load("./assets/terrain/color.png")
    game.terrain_height_tex = texture_load("./assets/terrain/height.png")
    height_img := img_load("./assets/terrain/height.png")
    defer image.destroy(height_img)
    game.terrain_height = new([TERRAIN_SIZE * TERRAIN_SIZE]u8)
    for i in 0 ..< TERRAIN_SIZE * TERRAIN_SIZE { game.terrain_height[i] = height_img.pixels.buf[i*3] }
    gl.UseProgram(game.sp_terrain)
    gl.ActiveTexture(gl.TEXTURE4)
    gl.BindTexture(gl.TEXTURE_2D, game.terrain_color_tex)
    gl.ActiveTexture(gl.TEXTURE5)
    gl.BindTexture(gl.TEXTURE_2D, game.terrain_height_tex)
    shader_set_int(game.sp_terrain, "color_tex", 4)
    shader_set_int(game.sp_terrain, "height_tex", 5)
    shader_set_uint(game.sp_terrain, "terrain_size", TERRAIN_SIZE)
    shader_set_float(game.sp_terrain, "terrain_scale", TERRAIN_SCALE)
    shader_set_float(game.sp_terrain, "render_width", WORLD_RENDER_WIDTH)
    shader_set_uint(game.sp_terrain, "render_height", WORLD_RENDER_HEIGHT)
    shader_set_uint(game.sp_terrain, "clip", CAM_CLIP)
    shader_set_vec3(game.sp_terrain, "sky_color", SKY_COLOR)
    
    // Grid shader setup
    gl.UseProgram(game.sp_grid)
    shader_set_uint(game.sp_grid, "tile_size", TILE_SIZE)

    // Solid shader setup
    gl.UseProgram(game.sp_solid)
    shader_set_float(game.sp_solid, "clip", CAM_CLIP)
    shader_set_float(game.sp_solid, "tile_size", TILE_SIZE)
    
    // Light shader setup
    gl.UseProgram(game.sp_light)
    shader_set_float(game.sp_light, "clip", CAM_CLIP)

    // Screen shader setup
    gl.UseProgram(game.sp_screen)
    shader_set_vec3(game.sp_screen, "sky_color", SKY_COLOR)
    shader_set_float(game.sp_screen, "fog_start", FOG_START)
    shader_set_vec2(game.sp_screen, "window_world_ratio", game.window_world_ratio * 2)
    
    // Load primitive meshes
    mesh_load_primitives(&game.primitives);

    // Load meshes
    //gltf_load(&game.meshes, "bunny", "./assets/bunny.glb")
}

game_setup :: proc(game: ^Game) {
    // Camera setup
    camera_set(game.camera, glsl.vec2(TILE_SIZE * 32.0 + TILE_SIZE * 0.5))

    // Light setup
    game.ambient_light   = { 0.2,  0.2,  0.2}
    game.dir_light.dir   = { 0.0, -1.0,  0.0}
    game.dir_light.color = { 0.5,  0.5,  0.5}
    light_add(game.lights, &game.num_lights,
        pos = {TILE_SIZE * 32.0, TILE_SIZE * 32.0},
        color = {1.0, 1.0, 1.0},
        constant = 1.0,
        linear = 0.14,
        quadratic = 0.07,
        mesh = &game.primitives[.Cube],
        scale = glsl.vec3(0.2),
    )
   
    // Model setup
    append(&game.models, Model{
        pos = glsl.vec2(TILE_SIZE * 32.0),
        scale = {1.0, 1.0, 1.0},
        mesh = &game.primitives[.Cube],
        color = {0.5, 0.5, 0.5},
    })
    /*
    append(&game.models, Model{
        pos = glsl.vec2{TILE_SIZE * 32.0, TILE_SIZE * 32.0},
        scale = {1.0, 1.0, 1.0},
        mesh = &game.meshes["bunny"],
        color = {0.5, 0.5, 0.5},
    })
    */
}

game_input :: proc(game: ^Game) {
    speed: f32 = 1.0
    if glfw.GetKey(game.window, glfw.KEY_LEFT_SHIFT) == glfw.PRESS || glfw.GetKey(game.window, glfw.KEY_RIGHT_SHIFT) == glfw.PRESS  { speed = 2.0 }
    if glfw.GetKey(game.window, glfw.KEY_ESCAPE) == glfw.PRESS { glfw.SetWindowShouldClose(game.window, true) }
    if glfw.GetKey(game.window, glfw.KEY_UP)     == glfw.PRESS { camera_modify(game.terrain_height[:], game.camera, dpos = { math.cos_f32(game.camera.rot.y) * speed * CAM_SPEED * f32(game.dt),  math.sin_f32(game.camera.rot.y) * speed * CAM_SPEED * f32(game.dt)})} 
    if glfw.GetKey(game.window, glfw.KEY_DOWN)   == glfw.PRESS { camera_modify(game.terrain_height[:], game.camera, dpos = {-math.cos_f32(game.camera.rot.y) * speed * CAM_SPEED * f32(game.dt), -math.sin_f32(game.camera.rot.y) * speed * CAM_SPEED * f32(game.dt)})} 
    if glfw.GetKey(game.window, glfw.KEY_LEFT)   == glfw.PRESS { camera_modify(game.terrain_height[:], game.camera, dpos = { math.sin_f32(game.camera.rot.y) * speed * CAM_SPEED * f32(game.dt), -math.cos_f32(game.camera.rot.y) * speed * CAM_SPEED * f32(game.dt)})} 
    if glfw.GetKey(game.window, glfw.KEY_RIGHT)  == glfw.PRESS { camera_modify(game.terrain_height[:], game.camera, dpos = {-math.sin_f32(game.camera.rot.y) * speed * CAM_SPEED * f32(game.dt),  math.cos_f32(game.camera.rot.y) * speed * CAM_SPEED * f32(game.dt)})} 
    if glfw.GetKey(game.window, glfw.KEY_W)      == glfw.PRESS { camera_modify(game.terrain_height[:], game.camera, dz =  200.0 * speed * f32(game.dt)) }
    if glfw.GetKey(game.window, glfw.KEY_S)      == glfw.PRESS { camera_modify(game.terrain_height[:], game.camera, dz = -200.0 * speed * f32(game.dt)) }
    if glfw.GetKey(game.window, glfw.KEY_A)      == glfw.PRESS { camera_modify(game.terrain_height[:], game.camera, drot =  1.5 * speed * f32(game.dt)) }
    if glfw.GetKey(game.window, glfw.KEY_D)      == glfw.PRESS { camera_modify(game.terrain_height[:], game.camera, drot = -1.5 * speed * f32(game.dt)) }
    if glfw.GetKey(game.window, glfw.KEY_Q)      == glfw.PRESS { camera_modify(game.terrain_height[:], game.camera, ddist =  150.0 * speed * f32(game.dt)) }
    if glfw.GetKey(game.window, glfw.KEY_E)      == glfw.PRESS { camera_modify(game.terrain_height[:], game.camera, ddist = -150.0 * speed * f32(game.dt)) }
}

game_update :: proc(game: ^Game) {
    // Update timekeeping variables
    game.time = glfw.GetTime()
    game.dt = game.time - game.prev_time
    if game.dt > 0.0 && game.fps_frame > game.fps {
        game.fps = u32(1.0 / game.dt)
        game.fps_frame = 0
    }
    game.prev_time = game.time
    game.fps_frame += 1
    game.frame += 1

    // Update positions / rotations
    game.lights[0].pos.x = math.sin_f32(f32(glfw.GetTime() * 1)) * TILE_SIZE * 2 + game.models[0].pos.x
    game.lights[0].pos.y = math.cos_f32(f32(glfw.GetTime() * 1)) * TILE_SIZE * 2 + game.models[0].pos.y
    //game.models[0].rot = {0.5, 1.0, 0.0} * f32(glfw.GetTime()) * glsl.radians_f32(10.0)
}

game_render :: proc(game: ^Game) {
    // Create projection and view matrix
    //aspect := f32(WINDOW_HEIGHT) / f32(WINDOW_WIDTH)
    //fov := 1.0 / math.tan_f32(glsl.radians_f32(45)/2.0)
    //proj_mat[0, 0] = aspect * fov
    //proj_mat[1, 1] = fov 
    offset_mat: glsl.mat4 = 1
    offset_mat[1, 3] = (WORLD_RENDER_HEIGHT - game.camera.rot.x) / WORLD_RENDER_HEIGHT * 2 - 1
    proj_mat: glsl.mat4 = 1
    proj_mat[0, 0] = 1
    proj_mat[1, 1] = f32(WORLD_RENDER_WIDTH) / f32(WORLD_RENDER_HEIGHT)
    proj_mat[2, 2] = -(CAM_CLIP + CAM_CLIP_NEAR) / (CAM_CLIP - CAM_CLIP_NEAR)
    proj_mat[2, 3] = -2.0 * CAM_CLIP * CAM_CLIP_NEAR / (CAM_CLIP - CAM_CLIP_NEAR)
    proj_mat[3, 2] = -1.0
    proj_mat[3, 3] =  0.0
    cam_pos := glsl.vec3{game.camera.pos.x, game.camera.z, game.camera.pos.y}
    cam_dir := glsl.normalize(glsl.vec3{game.camera.target.x, 0.0, game.camera.target.y} - glsl.vec3{cam_pos.x, 0.0, cam_pos.z})
    cam_right := glsl.normalize(glsl.cross_vec3({0.0, 1.0, 0.0}, cam_dir))
    cam_up := glsl.cross_vec3(cam_dir, cam_right)
    view_mat: glsl.mat4 = 1
    view_mat[0, 0] = -cam_right.x
    view_mat[0, 1] = -cam_right.y
    view_mat[0, 2] = -cam_right.z
    view_mat[0, 3] = glsl.dot_vec3(-cam_pos, -cam_right)
    view_mat[1, 0] = cam_up.x
    view_mat[1, 1] = cam_up.y
    view_mat[1, 2] = cam_up.z
    view_mat[1, 3] = glsl.dot_vec3(-cam_pos, cam_up)
    view_mat[2, 0] = -cam_dir.x
    view_mat[2, 1] = -cam_dir.y
    view_mat[2, 2] = -cam_dir.z
    view_mat[2, 3] = glsl.dot_vec3(-cam_pos, -cam_dir)
    view_mat_gl := glsl.mat4LookAt(cam_pos, cam_pos + cam_dir, cam_up)
    pv_mat := offset_mat * proj_mat * view_mat

    // Clear screen
    gl.ClearColor(0.2, 0.3, 0.3, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
    gl.BindVertexArray(game.vao)

    // Generate terrain colorbuffer and depthbuffer using compute shader
    gl.UseProgram(game.sp_terrain)
    shader_set_vec2(game.sp_terrain, "camera.pos", game.camera.pos)
    shader_set_float(game.sp_terrain, "camera.z", game.camera.z)
    shader_set_vec2(game.sp_terrain, "camera.target", game.camera.target)
    shader_set_vec2(game.sp_terrain, "camera.clip_l", game.camera.clip_l)
    shader_set_vec2(game.sp_terrain, "camera.clip_r", game.camera.clip_r)
    shader_set_vec2(game.sp_terrain, "camera.rot", game.camera.rot)
    gl.DispatchCompute(WORLD_RENDER_WIDTH/10, 1, 1)
    gl.MemoryBarrier(gl.SHADER_IMAGE_ACCESS_BARRIER_BIT)

    // Draw terrain colorbuffer to framebuffer
    gl.Enable(gl.DEPTH_TEST)
    gl.UseProgram(game.sp_screen)
    gl.DrawArrays(gl.TRIANGLE_FAN, 0, 4)

    // Draw 3D grid
    gl.Disable(gl.DEPTH_TEST)
    gl.UseProgram(game.sp_grid)
    shader_set_mat4(game.sp_grid, "pv_mat", offset_mat * proj_mat * view_mat)
    shader_set_float(game.sp_grid, "terrain_size", TERRAIN_SIZE)
    gl.DrawArrays(gl.TRIANGLE_FAN, 0, 4)

    // Draw 3D models
    gl.Enable(gl.DEPTH_TEST)
    gl.UseProgram(game.sp_solid)
    shader_set_mat4(game.sp_solid, "pv_mat", pv_mat)
    shader_set_vec3(game.sp_solid, "ambient_light", game.ambient_light)
    shader_set_vec3(game.sp_solid, "dir_light.dir", game.dir_light.dir)
    shader_set_vec3(game.sp_solid, "dir_light.color", game.dir_light.color)
    shader_set_int(game.sp_solid, "num_lights", i32(game.num_lights))
    for i in 0 ..< game.num_lights {
        shader_set_vec2(game.sp_solid, game.lights[i].u_name_pos, game.lights[i].pos)
        shader_set_vec3(game.sp_solid, game.lights[i].u_name_color, game.lights[i].color)
        shader_set_float(game.sp_solid, game.lights[i].u_name_constant, game.lights[i].constant)
        shader_set_float(game.sp_solid, game.lights[i].u_name_linear, game.lights[i].linear)
        shader_set_float(game.sp_solid, game.lights[i].u_name_quadratic, game.lights[i].quadratic)
    }
    for &model in game.models { model_render(&model, game.sp_solid, game.camera, game.terrain_height[:]) }
    gl.UseProgram(game.sp_light)
    shader_set_mat4(game.sp_light, "pv_mat", pv_mat)
    for i in 0 ..< game.num_lights { light_render(&game.lights[i], game.sp_light, game.camera, game.terrain_height[:]) }

    // Draw camera target gizmo
    gl.Disable(gl.DEPTH_TEST)
    gl.BindVertexArray(game.vao)
    gl.Enable(gl.LINE_SMOOTH)
    gl.LineWidth(2)
    gl.UseProgram(game.sp_gizmo)
    shader_set_mat4(game.sp_gizmo, "pv_mat", pv_mat)
    shader_set_vec2(game.sp_gizmo, "pos", game.camera.target)
    gl.DrawArrays(gl.LINES, 0, 6)
    

    // Draw font
    gl.Disable(gl.DEPTH_TEST)
    gl.UseProgram(game.sp_font)
    gl.BindVertexArray(game.font_vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, game.font_vbo)
    font_render(game, 2, 0, game.fps, 2, game.fps >= 50 ? {0.2, 0.8, 0.2} : (game.fps >= 30 ? {0.8, 0.8, 0.2} : {0.8, 0.2, 0.2} ))
    font_render(game, 2, 1080-16, fmt.tprintf("camera: pos=(%.f, %.f, %.f) rot=(%.2f, %.2f)", game.camera.pos.x, game.camera.pos.y, game.camera.z, game.camera.rot.x, game.camera.rot.y))
    gl.BindVertexArray(0)
    gl.BindBuffer(gl.ARRAY_BUFFER, 0)
    
    // Swap buffers
    glfw.SwapBuffers(game.window)
    gl_check_error()
}

game_exit :: proc(game: ^Game) {
    free(game.terrain_height)
    free(game.font_chars)
    free(game.lights)
    gl.DeleteProgram(game.sp_screen)
    gl.DeleteProgram(game.sp_terrain)
    gl.DeleteProgram(game.sp_font)
    gl.DeleteProgram(game.sp_solid)
    gl.DeleteProgram(game.sp_light)
    gl.DeleteProgram(game.sp_grid)
    gl.DeleteProgram(game.sp_gizmo)
    gl.DeleteVertexArrays(1, &game.vao)
    gl.DeleteBuffers(1, &game.vbo)
    gl.DeleteTextures(1, &game.font_tex)
    gl.DeleteTextures(1, &game.terrain_colorbuf)
    gl.DeleteTextures(1, &game.terrain_depthbuf)
    gl.DeleteTextures(1, &game.terrain_color_tex)
    gl.DeleteTextures(1, &game.terrain_height_tex)
    for i in 0..< game.num_lights { light_destroy(&game.lights[i]) }
    for key, &mesh in game.primitives { mesh_destroy(&mesh) }
    for key, &mesh in game.meshes { mesh_destroy(&mesh) }
    delete(game.primitives)
    delete(game.meshes)
    delete(game.models)
    glfw.Terminate()
}
