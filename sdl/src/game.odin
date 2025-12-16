package main

import "core:log"
import "core:math"
import "core:os"
import "core:fmt"
import "vendor:sdl2"

Game :: struct {
    running: bool,
    window: ^sdl2.Window,
    renderer: ^sdl2.Renderer,
    render_texture: ^sdl2.Texture,
    colorbuffer: ^[RENDER_HEIGHT * RENDER_WIDTH]u32,
    camera: ^Camera,
    terrain: ^Terrain,
    keystate: [^]u8,
    ui_txt: string,
}

init :: proc(game: ^Game) {
    if !init_sdl(game) {
        log.errorf("SDL initialization failed.")
        os.exit(1)
    }
    game.colorbuffer = new([RENDER_HEIGHT * RENDER_WIDTH]u32)
    terrain_load(game.terrain)
    camera_update(game.camera)
    game.keystate = sdl2.GetKeyboardState(nil)
    game.ui_txt = "abdefghijklmnopqrstuvwxyz"
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
            }
        }
    }
    if game.keystate[sdl2.SCANCODE_LEFT] == 1 {
        camera_move(game.terrain, game.camera, -math.sin_f32(game.camera.rot) * CAM_SPEED, -math.cos_f32(game.camera.rot) * CAM_SPEED)
    }
    if game.keystate[sdl2.SCANCODE_RIGHT] == 1 {
        camera_move(game.terrain, game.camera, math.sin_f32(game.camera.rot) * CAM_SPEED, math.cos_f32(game.camera.rot) * CAM_SPEED)
    }
    if game.keystate[sdl2.SCANCODE_UP] == 1 {
        camera_move(game.terrain, game.camera, math.cos_f32(game.camera.rot) * CAM_SPEED, math.sin_f32(game.camera.rot) * CAM_SPEED)
    }
    if game.keystate[sdl2.SCANCODE_DOWN] == 1 {
        camera_move(game.terrain, game.camera, -math.cos_f32(game.camera.rot) * CAM_SPEED, -math.sin_f32(game.camera.rot) * CAM_SPEED)
    }
    if game.keystate[sdl2.SCANCODE_A] == 1 {
        game.camera.rot -= 0.03
        camera_update(game.camera)
    }
    if game.keystate[sdl2.SCANCODE_D] == 1 {
        game.camera.rot += 0.03
        camera_update(game.camera)
    }
    if game.keystate[sdl2.SCANCODE_W] == 1 {
        camera_change_height(game.terrain, game.camera, 3)
    }
    if game.keystate[sdl2.SCANCODE_S] == 1 {
        camera_change_height(game.terrain, game.camera, -3)
    }
}

update :: proc(game: ^Game) {
}

draw :: proc(game: ^Game, fps: int) {
    sdl2.SetRenderDrawColor(game.renderer, 50, 50, 50, 0xff)
    sdl2.RenderClear(game.renderer)    
    for i := 0; i < RENDER_HEIGHT * RENDER_WIDTH; i+=1 {
        game.colorbuffer[i] = 0x000000
    }
    terrain_render(game.colorbuffer[:], game.camera, game.terrain)
    draw_int(game.colorbuffer[:], fps, 10, 10, 0x00ff00)
    draw_string(game.colorbuffer[:], game.ui_txt, 10, 26, 0xffffff)
    sdl2.UpdateTexture(
        game.render_texture,
        nil,
        raw_data(game.colorbuffer),
        RENDER_WIDTH * 4
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
    game.render_texture = sdl2.CreateTexture(game.renderer, sdl2.PixelFormatEnum.RGBA32, sdl2.TextureAccess.STREAMING, RENDER_WIDTH, RENDER_HEIGHT)
    if game.render_texture == nil {
        log.errorf("sdl2.CreateTexture failed.")
        return false
    }
    return true
}
