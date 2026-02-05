package main
import "core:fmt"
import "core:strings"
import "core:os"
import "core:log"
import "core:math"
import "vendor:glfw"
import "core:math/linalg/glsl"
import gl "vendor:OpenGL"

Game :: struct {
    window:             glfw.WindowHandle,
    ndc_pixel_w:        f32,
    ndc_pixel_h:        f32,
    sp_terrain:         u32,
    sp_screen:          u32,
    sp_font:            u32,
    font_tex:           u32,
    terrain_colorbuf:   u32,
    terrain_depthbuf:   u32,
    terrain_color_tex:  u32,
    terrain_height_tex: u32,
    camera:             ^Camera,
    vao:                u32,
    vbo:                u32,
    frame:              u32,
    time:               f64,
    prev_time:          f64,
    dt:                 f64,
    fps:                u32,
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
    game.ndc_pixel_w = 1.0 / WINDOW_WIDTH
    game.ndc_pixel_h = 1.0 / WINDOW_HEIGHT
    
    // OpenGL settings
    gl.Enable(gl.CULL_FACE)
    gl.Enable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
    if OPTION_GAMMA_CORRECTION { gl.Enable(gl.FRAMEBUFFER_SRGB) }
    if OPTION_ANTI_ALIAS { gl.Enable(gl.MULTISAMPLE) }

    // Vertex array object & vertex buffer object setup
    gl.GenVertexArrays(1, &game.vao)
    gl.GenBuffers(1, &game.vbo)
    gl.BindVertexArray(game.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, game.vbo)

    // Load shaders
    shader_load_vs_fs(&game.sp_font, SHADER_FONT_VERT, SHADER_FONT_FRAG)
    shader_load_vs_fs(&game.sp_screen, SHADER_SCREEN_VERT, SHADER_SCREEN_FRAG)
    shader_load_cs(&game.sp_terrain, SHADER_TERRAIN)

    // Terrain colorbuffer setup
    gl.GenTextures(1, &game.terrain_colorbuf)
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, game.terrain_colorbuf)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA32F, WORLD_RENDER_WIDTH, WORLD_RENDER_HEIGHT, 0, gl.RGBA, gl.UNSIGNED_BYTE, nil)
    gl.BindImageTexture(0, game.terrain_colorbuf, 0, gl.FALSE, 0, gl.READ_ONLY, gl.RGBA32F)
    
    // Terrain depthbuffer setup
    gl.GenTextures(1, &game.terrain_depthbuf)
    gl.ActiveTexture(gl.TEXTURE1)
    gl.BindTexture(gl.TEXTURE_2D, game.terrain_depthbuf)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.R32F, WORLD_RENDER_WIDTH, WORLD_RENDER_HEIGHT, 0, gl.RED, gl.UNSIGNED_BYTE, nil)
    gl.BindImageTexture(1, game.terrain_depthbuf, 0, gl.FALSE, 0, gl.READ_ONLY, gl.R32F)

    // Load font
    game.font_tex = texture_load(FONT_PATH, filtering = false)
    
    // Load terrain textures
    game.terrain_color_tex = texture_load("./assets/terrain/color.png", filtering = false)
    game.terrain_height_tex = texture_load("./assets/terrain/height.png", filtering = false)

    // Shader program and texture unit setup
    gl.UseProgram(game.sp_screen)
    shader_set_int(game.sp_screen, "terrain_colorbuf", 0)
    shader_set_int(game.sp_screen, "terrain_depthbuf", 1)
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, game.terrain_colorbuf)
    gl.ActiveTexture(gl.TEXTURE1)
    gl.BindTexture(gl.TEXTURE_2D, game.terrain_depthbuf)
    gl.UseProgram(game.sp_font)
    shader_set_int(game.sp_font, "font_tex", 2)
    gl.ActiveTexture(gl.TEXTURE2)
    gl.BindTexture(gl.TEXTURE_2D, game.font_tex)
    gl.UseProgram(game.sp_terrain)
    shader_set_float(game.sp_terrain, "render_width", WORLD_RENDER_WIDTH)
    shader_set_uint(game.sp_terrain, "render_height", WORLD_RENDER_HEIGHT)
    shader_set_uint(game.sp_terrain, "cam_clip", CAM_CLIP)
    shader_set_uint(game.sp_terrain, "terrain_size", TERRAIN_SIZE)
    shader_set_float(game.sp_terrain, "terrain_scale", TERRAIN_SCALE)
    shader_set_vec3(game.sp_terrain, "sky_color", SKY_COLOR)
    shader_set_int(game.sp_terrain, "color_tex", 3)
    gl.ActiveTexture(gl.TEXTURE3)
    gl.BindTexture(gl.TEXTURE_2D, game.terrain_color_tex)
    shader_set_int(game.sp_terrain, "height_tex", 4)
    gl.ActiveTexture(gl.TEXTURE4)
    gl.BindTexture(gl.TEXTURE_2D, game.terrain_height_tex)
}

game_setup :: proc(game: ^Game) {
    camera_set(game.camera, {512.0, 512.0})
}

game_input :: proc(game: ^Game) {
    if glfw.GetKey(game.window, glfw.KEY_ESCAPE) == glfw.PRESS { glfw.SetWindowShouldClose(game.window, true) }
    if glfw.GetKey(game.window, glfw.KEY_UP)     == glfw.PRESS { camera_modify(game.camera, dpos = { math.cos_f32(game.camera.rot) * CAM_SPEED * f32(game.dt),  math.sin_f32(game.camera.rot) * CAM_SPEED * f32(game.dt)})} 
    if glfw.GetKey(game.window, glfw.KEY_DOWN)   == glfw.PRESS { camera_modify(game.camera, dpos = {-math.cos_f32(game.camera.rot) * CAM_SPEED * f32(game.dt), -math.sin_f32(game.camera.rot) * CAM_SPEED * f32(game.dt)})} 
    if glfw.GetKey(game.window, glfw.KEY_LEFT)   == glfw.PRESS { camera_modify(game.camera, dpos = { math.sin_f32(game.camera.rot) * CAM_SPEED * f32(game.dt), -math.cos_f32(game.camera.rot) * CAM_SPEED * f32(game.dt)})} 
    if glfw.GetKey(game.window, glfw.KEY_RIGHT)  == glfw.PRESS { camera_modify(game.camera, dpos = {-math.sin_f32(game.camera.rot) * CAM_SPEED * f32(game.dt),  math.cos_f32(game.camera.rot) * CAM_SPEED * f32(game.dt)})} 
    if glfw.GetKey(game.window, glfw.KEY_W)      == glfw.PRESS { camera_modify(game.camera, dz =  200.0 * f32(game.dt)) }
    if glfw.GetKey(game.window, glfw.KEY_S)      == glfw.PRESS { camera_modify(game.camera, dz = -200.0 * f32(game.dt)) }
    if glfw.GetKey(game.window, glfw.KEY_A)      == glfw.PRESS { camera_modify(game.camera, drot =  1.0 * f32(game.dt)) }
    if glfw.GetKey(game.window, glfw.KEY_D)      == glfw.PRESS { camera_modify(game.camera, drot = -1.0 * f32(game.dt)) }
    if glfw.GetKey(game.window, glfw.KEY_Q)      == glfw.PRESS { camera_modify(game.camera, ddist =  100.0 * f32(game.dt)) }
    if glfw.GetKey(game.window, glfw.KEY_E)      == glfw.PRESS { camera_modify(game.camera, ddist = -100.0 * f32(game.dt)) }
}

game_update :: proc(game: ^Game) {
    game.time = glfw.GetTime()
    game.dt = game.time - game.prev_time
    if game.dt > 0.0 && game.frame > game.fps {
        game.fps = u32(1.0 / game.dt)
        game.frame = 0
    }
    game.prev_time = game.time
    game.frame += 1
}

game_render :: proc(game: ^Game) {
    // Clear screen
    gl.ClearColor(0.2, 0.3, 0.3, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
    gl.Enable(gl.DEPTH_TEST)

    // Generate terrain colorbuffer and depthbuffer using compute shader
    gl.UseProgram(game.sp_terrain)
    shader_set_vec2(game.sp_terrain, "camera.chunk_pos", game.camera.chunk_pos)
    shader_set_vec2(game.sp_terrain, "camera.clip_l", game.camera.clip_l)
    shader_set_vec2(game.sp_terrain, "camera.clip_r", game.camera.clip_r)
    shader_set_float(game.sp_terrain, "camera.z", game.camera.z)
    shader_set_float(game.sp_terrain, "camera.tilt", game.camera.tilt)
    gl.DispatchCompute(WORLD_RENDER_WIDTH/10, 1, 1)
    gl.MemoryBarrier(gl.SHADER_IMAGE_ACCESS_BARRIER_BIT)

    // Draw terrain colorbuffer to framebuffer
    gl.UseProgram(game.sp_screen)
    gl.DrawArrays(gl.TRIANGLE_FAN, 0, 4)

    // Draw font
    gl.Disable(gl.DEPTH_TEST)
    gl.UseProgram(game.sp_font)
    font_render_u32(game, 4, 0, 2, game.fps >= 50 ? {0.2, 0.8, 0.2} : (game.fps >= 30 ? {0.8, 0.8, 0.2} : {0.8, 0.2, 0.2} ), game.fps)
    font_render_string(game, 4, 1080-32, 2, {1.0, 1.0, 1.0}, game.camera.txt)

    // Swap buffers
    glfw.SwapBuffers(game.window)
    gl_check_error()
}

game_exit :: proc(game: ^Game) {
    gl.DeleteProgram(game.sp_screen)
    gl.DeleteProgram(game.sp_terrain)
    gl.DeleteProgram(game.sp_font)
    glfw.Terminate()
}
