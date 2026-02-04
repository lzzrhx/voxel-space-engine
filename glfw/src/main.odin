package main

import "core:log"
import "core:mem"
import "vendor:glfw"


WINDOW_WIDTH            :: 1920
WINDOW_HEIGHT           :: 1080
WINDOW_TITLE            :: "gl"
GL_VERSION_MAJOR        :: 4
GL_VERSION_MINOR        :: 3
SHADER_SCREEN_VERT      :: "./src/shaders/screen.vert"
SHADER_SCREEN_FRAG      :: "./src/shaders/screen.frag"
SHADER_COMPUTE          :: "./src/shaders/compute.comp"
SHADER_FONT_VERT        :: "./src/shaders/font.vert"
SHADER_FONT_FRAG        :: "./src/shaders/font.frag"
RENDER_TEXTURE_WIDTH    :: 1000
RENDER_TEXTURE_HEIGHT   :: 1000
OPTION_VSYNC            :: false
OPTION_ANTI_ALIAS       :: true
OPTION_GAMMA_CORRECTION :: true
TEXTURE_FONT            :: "./assets/font.png"
FONT_WIDTH              :: 8
FONT_HEIGHT             :: 16


main :: proc() {
    // Tracking allocator and logger set up
    defer free_all(context.temp_allocator)
    context.logger = log.create_console_logger()
    tracking_allocator: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking_allocator, context.allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    defer mem_check_leaks(&tracking_allocator)

    // Program initialization
    game := &Game{}
    game_init(game)
    game_setup(game)

    // Main Loop
    for !glfw.WindowShouldClose(game.window) {
        game_input(game)
        game_update(game)
        game_render(game)
        glfw.PollEvents()
        mem_check_bad_free(&tracking_allocator)
    }
   
    // Exit the program
    game_exit(game)
}
