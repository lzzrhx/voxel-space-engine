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
    window:         glfw.WindowHandle,
    sp_compute:     u32,
    sp_screen:      u32,
    sp_font:        u32,
    vao:            u32,
    vbo:            u32,
    frame:          u32,
    time:           f64,
    prev_time:      f64,
    dt:             f64,
    fps:            u32,
    texture_render: u32,
    texture_depth: u32,
    texture_font:   u32,
    texture_terrain_color:   u32,
    texture_terrain_height:   u32,
    ndc_pixel_w:    f32,
    ndc_pixel_h:    f32,
    camera:         ^Camera,
    option_render_depthbuffer: bool,
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

    // Load shaders
    shader_load_vs_fs(&game.sp_font, SHADER_FONT_VERT, SHADER_FONT_FRAG)
    shader_load_vs_fs(&game.sp_screen, SHADER_SCREEN_VERT, SHADER_SCREEN_FRAG)
    shader_load_cs(&game.sp_compute, SHADER_TERRAIN)

    // Render texture setup
    gl.GenTextures(1, &game.texture_render)
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, game.texture_render)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA32F, RENDER_TEXTURE_WIDTH, RENDER_TEXTURE_HEIGHT, 0, gl.RGBA, gl.FLOAT, nil)
    gl.BindImageTexture(0, game.texture_render, 0, gl.FALSE, 0, gl.READ_ONLY, gl.RGBA32F)
    
    // Depth texture setup
    gl.GenTextures(1, &game.texture_depth)
    gl.ActiveTexture(gl.TEXTURE1)
    gl.BindTexture(gl.TEXTURE_2D, game.texture_depth)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.R8, RENDER_TEXTURE_WIDTH, RENDER_TEXTURE_HEIGHT, 0, gl.RED, gl.FLOAT, nil)
    gl.BindImageTexture(1, game.texture_depth, 0, gl.FALSE, 0, gl.READ_ONLY, gl.R8)
    
    // Load font
    game.texture_font = texture_load(TEXTURE_FONT, filtering = false)
    
    // Load terrain textures
    game.texture_terrain_color = texture_load("./assets/terrain/color.png", filtering = false)
    game.texture_terrain_height = texture_load("./assets/terrain/height.png", filtering = false)

    // Shader program and texture unit setup
    gl.UseProgram(game.sp_screen)
    shader_set_int(game.sp_screen, "texture_render", 0)
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, game.texture_render)
    gl.UseProgram(game.sp_font)
    shader_set_int(game.sp_font, "texture_font", 2)
    gl.ActiveTexture(gl.TEXTURE2)
    gl.BindTexture(gl.TEXTURE_2D, game.texture_font)
    gl.UseProgram(game.sp_compute)
    shader_set_float(game.sp_compute, "width", RENDER_TEXTURE_WIDTH)
    shader_set_uint(game.sp_compute, "height", RENDER_TEXTURE_HEIGHT)
    shader_set_uint(game.sp_compute, "cam_clip", CAM_CLIP)
    shader_set_uint(game.sp_compute, "terrain_size", TERRAIN_SIZE)
    shader_set_float(game.sp_compute, "terrain_scale", TERRAIN_SCALE)
    shader_set_vec3(game.sp_compute, "sky_color", SKY_COLOR)
    shader_set_int(game.sp_compute, "texture_terrain_color", 3)
    gl.ActiveTexture(gl.TEXTURE3)
    gl.BindTexture(gl.TEXTURE_2D, game.texture_terrain_color)
    shader_set_int(game.sp_compute, "texture_terrain_height", 4)
    gl.ActiveTexture(gl.TEXTURE4)
    gl.BindTexture(gl.TEXTURE_2D, game.texture_terrain_height)

    // Vertex array object & vertex buffer object setup
    gl.GenVertexArrays(1, &game.vao)
    gl.GenBuffers(1, &game.vbo)
    gl.BindVertexArray(game.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, game.vbo)
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
    gl_check_error()
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

    // Generate render texture using compute shader
    gl.UseProgram(game.sp_compute)
    shader_set_vec2(game.sp_compute, "camera.chunk_pos", game.camera.chunk_pos)
    shader_set_vec2(game.sp_compute, "camera.clip_l", game.camera.clip_l)
    shader_set_vec2(game.sp_compute, "camera.clip_r", game.camera.clip_r)
    shader_set_float(game.sp_compute, "camera.z", game.camera.z)
    shader_set_float(game.sp_compute, "camera.tilt", game.camera.tilt)
    gl.DispatchCompute(RENDER_TEXTURE_WIDTH/10, 1, 1)
    gl.MemoryBarrier(gl.SHADER_IMAGE_ACCESS_BARRIER_BIT)

    // Display render texture
    gl.UseProgram(game.sp_screen)
    gl.DrawArrays(gl.TRIANGLE_FAN, 0, 4)

    // Render font
    gl.Disable(gl.DEPTH_TEST)
    gl.UseProgram(game.sp_font)
    font_render_u32(game, 4, 0, 2, game.fps >= 50 ? {0.2, 0.8, 0.2} : (game.fps >= 30 ? {0.8, 0.8, 0.2} : {0.8, 0.2, 0.2} ), game.fps)
    font_render_string(game, 0, 1080-32, 2, {1.0, 1.0, 1.0}, game.camera.txt)

    // Swap buffers
    glfw.SwapBuffers(game.window)
}


game_exit :: proc(game: ^Game) {
    gl.DeleteProgram(game.sp_screen)
    gl.DeleteProgram(game.sp_compute)
    glfw.Terminate()
}
