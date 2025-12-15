package main

import "core:log"
import "core:os"
import "vendor:sdl2"

// Constants
WINDOW_TITLE :: "Voxel"
WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 600
WINDOW_FLAGS :: sdl2.WindowFlags{.SHOWN}

Game :: struct {
    running: bool,
    window: ^sdl2.Window,
    renderer: ^sdl2.Renderer,
    render_texture: ^sdl2.Texture,
    frame_start: f64,
    frame_end: f64,
    frame_elapsed: f64,
}
game := Game{ running = true, frame_elapsed = 0.001 }

// Initialize SDL2
init_sdl :: proc() -> bool {
    if sdl_res := sdl2.Init(sdl2.INIT_VIDEO); sdl_res < 0 {
        log.errorf("sdl2.Init returned %v", sdl_res)
        return false
    }
    // Create window
    game.window = sdl2.CreateWindow(WINDOW_TITLE, sdl2.WINDOWPOS_CENTERED, sdl2.WINDOWPOS_CENTERED, WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_FLAGS)
    if game.window == nil {
        log.errorf("sdl2.CreateWindow failed.")
        return false
    }
    // Create renderer
    game.renderer = sdl2.CreateRenderer(game.window, -1, {.ACCELERATED, .PRESENTVSYNC})
    if game.renderer == nil {
        log.errorf("sdl2.CreateRenderer failed.")
        return false
    }
    // Create color buffer texture
    game.render_texture = sdl2.CreateTexture(game.renderer, sdl2.PixelFormatEnum.RGBA32, sdl2.TextureAccess.STREAMING, WINDOW_WIDTH, WINDOW_HEIGHT)
    if game.render_texture == nil {
        log.errorf("sdl2.CreateTexture failed.")
        return false
    }
    return true
}


// Process input
input :: proc() {
    e: sdl2.Event
    for sdl2.PollEvent(&e) {
        #partial switch(e.type) {
        case .QUIT:
            game.running = false
        case .KEYDOWN:
            #partial switch(e.key.keysym.sym) {
            case .ESCAPE:
                game.running = false
            }
        }
    }
}

// Update things
update :: proc() {
}

// Render the color buffer
render :: proc(color_buffer: []u32) {
    sdl2.SetRenderDrawColor(game.renderer, 50, 50, 50, 0xff)
    sdl2.RenderClear(game.renderer)    
    for i := 0; i < WINDOW_HEIGHT * WINDOW_WIDTH; i+=1 {
        color_buffer[i] = 0x000000
    }
    color_buffer[10+10*WINDOW_WIDTH] = 0xffffff
    sdl2.UpdateTexture(
        game.render_texture,
        nil,
        raw_data(color_buffer),
        WINDOW_WIDTH * 4
    )
    sdl2.RenderCopy(game.renderer, game.render_texture, nil, nil)
    sdl2.RenderPresent(game.renderer)
}

// Exit the program
exit :: proc() {
    sdl2.DestroyWindow(game.window)
    sdl2.Quit()
}

// Program entry-point
main :: proc() {
    context.logger = log.create_console_logger()
    // Initialization
    if ok := init_sdl(); !ok {
        log.errorf("SDL initialization failed.")
        os.exit(1)
    }
    color_buffer: ^[WINDOW_HEIGHT * WINDOW_WIDTH]u32 = new([WINDOW_HEIGHT * WINDOW_WIDTH]u32)
    defer free(color_buffer)
    // Main loop
    game.frame_start = f64(sdl2.GetPerformanceCounter()) / f64(sdl2.GetPerformanceFrequency())
    for game.running {
        input()
        update()
        render(color_buffer[:])
        game.frame_end = f64(sdl2.GetPerformanceCounter()) / f64(sdl2.GetPerformanceFrequency())
        game.frame_elapsed = game.frame_end - game.frame_start
        game.frame_start = game.frame_end
    }
    // Execution finished
    defer exit()
}
