package main
import "core:log"
import "core:mem"
import "vendor:glfw"


WINDOW_WIDTH              :: 1920
WINDOW_HEIGHT             :: 1080
WINDOW_TITLE              :: "gl"
GL_VERSION_MAJOR          :: 4
GL_VERSION_MINOR          :: 3
SHADER_SCREEN_VERT        :: "./src/glsl/screen.vert"
SHADER_SCREEN_FRAG        :: "./src/glsl/screen.frag"
SHADER_COMPUTE            :: "./src/glsl/compute.comp"
SHADER_FONT_VERT          :: "./src/glsl/font.vert"
SHADER_FONT_FRAG          :: "./src/glsl/font.frag"
RENDER_TEXTURE_WIDTH      :: 960
RENDER_TEXTURE_HEIGHT     :: 540
OPTION_VSYNC              :: false
OPTION_ANTI_ALIAS         :: true
OPTION_GAMMA_CORRECTION   :: true
TEXTURE_FONT              :: "./assets/font.png"
FONT_WIDTH                :: 8
FONT_HEIGHT               :: 16
TERRAIN_DEFAULT_COLORMAP  :: "./assets/terrain/default-color.png"
TERRAIN_DEFAULT_HEIGHTMAP :: "./assets/terrain/default-height.png"
CAM_CLIP                  :: 700
CAM_Z_MIN              :f32: 0
CAM_Z_MAX              :f32: 400
TERRAIN_SIZE              :: 1024
TERRAIN_SCALE             :: 100


main :: proc() {
    // Tracking allocator and logger set up
    defer free_all(context.temp_allocator)
    context.logger = log.create_console_logger()
    tracking_allocator: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking_allocator, context.allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    defer mem_check_leaks(&tracking_allocator)

    // Program initialization
    game := &Game{ camera = &Camera{} }
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
