package main

import "core:log"
import "core:math"
import "core:os"
import "vendor:sdl2"

Game :: struct {
    running: bool,
    window: ^sdl2.Window,
    renderer: ^sdl2.Renderer,
    render_texture: ^sdl2.Texture,
    colorbuffer: ^[WINDOW_HEIGHT * WINDOW_WIDTH]u32,
    camera: ^Camera,
    terrain: ^Terrain,
}

init :: proc(game: ^Game) {
    if !init_sdl(game) {
        log.errorf("SDL initialization failed.")
        os.exit(1)
    }
    game.colorbuffer = new([WINDOW_HEIGHT * WINDOW_WIDTH]u32)
    terrain_load(game.terrain)
}

input :: proc(game: ^Game) {
    e: sdl2.Event
    for sdl2.PollEvent(&e) {
        #partial switch(e.type) {
        case .QUIT:
            game.running = false
        case .KEYDOWN:
            #partial switch(e.key.keysym.sym) {
            case .ESCAPE:
                game.running = false
            case .LEFT:
                game.camera.x -= math.sin_f32(game.camera.rot) * CAM_SPEED
                game.camera.y -= math.cos_f32(game.camera.rot) * CAM_SPEED
            case .RIGHT:
                game.camera.x += math.sin_f32(game.camera.rot) * CAM_SPEED
                game.camera.y += math.cos_f32(game.camera.rot) * CAM_SPEED
            case .UP:
                game.camera.x += math.cos_f32(game.camera.rot) * CAM_SPEED
                game.camera.y += math.sin_f32(game.camera.rot) * CAM_SPEED
            case .DOWN:
                game.camera.x -= math.cos_f32(game.camera.rot) * CAM_SPEED
                game.camera.y -= math.sin_f32(game.camera.rot) * CAM_SPEED
            case .A:
                game.camera.rot -= 0.05
            case .D:
                game.camera.rot += 0.05
            case .W:
                game.camera.z += 3.0
                game.camera.tilt -= 1.5
            case .S:
                game.camera.z -= 3.0
                game.camera.tilt += 1.5
            }
        }
    }
}

update :: proc(game: ^Game) {
    camera_update(game.camera)
}

draw :: proc(game: ^Game) {
    sdl2.SetRenderDrawColor(game.renderer, 50, 50, 50, 0xff)
    sdl2.RenderClear(game.renderer)    
    for i := 0; i < WINDOW_HEIGHT * WINDOW_WIDTH; i+=1 {
        game.colorbuffer[i] = 0x000000
    }
    terrain_render(game.colorbuffer[:], game.camera, game.terrain)
    draw_line(game.colorbuffer[:], 10, 10, 70, 70, u32(0xff0000))
    sdl2.UpdateTexture(
        game.render_texture,
        nil,
        raw_data(game.colorbuffer),
        WINDOW_WIDTH * 4
    )
    sdl2.RenderCopy(game.renderer, game.render_texture, nil, nil)
    sdl2.RenderPresent(game.renderer)
}

exit :: proc(game: ^Game) {
    terrain_destroy(game.terrain)
    free(game.colorbuffer)
    sdl2.DestroyWindow(game.window)
    sdl2.Quit()
}

init_sdl :: proc(game: ^Game) -> bool {
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
