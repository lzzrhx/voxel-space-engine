package main

import "core:log"
import "core:math"
import "core:os"
import "core:fmt"
import "vendor:sdl2"
import "base:runtime"

Game :: struct {
    running: bool,
    window: ^sdl2.Window,
    renderer: ^sdl2.Renderer,
    render_texture: ^sdl2.Texture,
    ui_layer: ^Ui_Layer,
    world_layer: ^World_Layer,
    camera: ^Camera,
    terrain: ^Terrain,
    keystate: [^]u8,
    entities: [dynamic]Entity,
}

Ui_Layer :: struct {
    colorbuffer: ^Colorbuffer,
    drawn_areas: ^Rects,
}

World_Layer :: struct {
    colorbuffer: ^Colorbuffer,
    depthbuffer: ^Depthbuffer,
}

init :: proc(game: ^Game) {
    if !init_sdl(game) {
        log.errorf("SDL initialization failed.")
        os.exit(1)
    }
    terrain_load(game.terrain)
    camera_update(game.camera)
    entity_new(&game.entities, 530, 280)
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
    game.renderer = sdl2.CreateRenderer(game.window, -1, {.ACCELERATED, .PRESENTVSYNC, .TARGETTEXTURE})
    if game.renderer == nil {
        log.errorf("sdl2.CreateRenderer failed.")
        return false
    }
    // Create render texture
    game.render_texture = sdl2.CreateTexture(game.renderer, .RGBA32, .TARGET, RENDER_WIDTH, RENDER_HEIGHT)
    if game.render_texture == nil {
        log.errorf("sdl2.CreateTexture failed.")
        return false
    }
    // Create colorbuffer texture for ui rendering
    game.ui_layer.colorbuffer.texture = sdl2.CreateTexture(game.renderer, .RGBA32, .STREAMING, i32(game.ui_layer.colorbuffer.width), i32(game.ui_layer.colorbuffer.height))
    if game.ui_layer.colorbuffer.texture == nil {
        log.errorf("sdl2.CreateTexture failed.")
        return false
    }
    // Create colorbuffer texture for world rendering
    game.world_layer.colorbuffer.texture = sdl2.CreateTexture(game.renderer, .RGBA32, .STREAMING, i32(game.world_layer.colorbuffer.width), i32(game.world_layer.colorbuffer.height))
    if game.world_layer.colorbuffer.texture == nil {
        log.errorf("sdl2.CreateTexture failed.")
        return false
    }
    sdl2.SetTextureBlendMode(game.ui_layer.colorbuffer.texture, .BLEND)
    game.keystate = sdl2.GetKeyboardState(nil)
    return true
}

input :: proc(game: ^Game) {
    e: sdl2.Event
    for sdl2.PollEvent(&e) {
        #partial switch(e.type) {
        case .QUIT: game.running = false
        case .KEYDOWN:
            #partial switch(e.key.keysym.sym) {
            case .ESCAPE: game.running = false
            }
        }
    }
    if game.keystate[sdl2.SCANCODE_UP] == 1 { camera_move(game.terrain, game.camera, 0.0, -CAM_SPEED) }
    if game.keystate[sdl2.SCANCODE_DOWN] == 1 { camera_move(game.terrain, game.camera, 0.0, CAM_SPEED) }
    if game.keystate[sdl2.SCANCODE_LEFT] == 1 { camera_move(game.terrain, game.camera, -CAM_SPEED, 0.0) }
    if game.keystate[sdl2.SCANCODE_RIGHT] == 1 { camera_move(game.terrain, game.camera, CAM_SPEED, 0.0) }
    if game.keystate[sdl2.SCANCODE_W] == 1 { camera_change_height(game.terrain, game.camera, 3) }
    if game.keystate[sdl2.SCANCODE_S] == 1 { camera_change_height(game.terrain, game.camera, -3) }
}

update :: proc(game: ^Game) {
}

draw :: proc(game: ^Game, fps: int) {
    if game.ui_layer.drawn_areas.num > 0 {
        // Clear ui buffer
        for i in 0 ..< game.ui_layer.drawn_areas.num {
            area := game.ui_layer.drawn_areas.rects[i]
            for x in area.x ..< area.x + area.width {
                for y in area.y ..< area.y + area.height {
                    game.ui_layer.colorbuffer.buf[x + y * game.ui_layer.colorbuffer.width] = 0x00_00_00_00
                }
            }
        }
        game.ui_layer.drawn_areas.num = 0
    }
    // Clear world buffer
    for i := 0; i < game.world_layer.colorbuffer.width * game.world_layer.colorbuffer.height; i+=1 {
        game.world_layer.colorbuffer.buf[i] = 0x00_00_00_00
        game.world_layer.depthbuffer.buf[i] = 0xff_ff
    }
    // Draw to buffers
    terrain_render(game.world_layer, game.camera, game.terrain)
    entities_render(game.world_layer, game.camera, game.terrain, &game.entities)
    draw_int(game.ui_layer, fps, 1, 0, 0xff_00_ff_00)
    draw_string(game.ui_layer, game.camera.txt, 1, game.ui_layer.colorbuffer.height-16, 0xff_ff_ff_ff)
    // Update buffer textures
    sdl2.UpdateTexture(
        game.ui_layer.colorbuffer.texture,
        nil,
        raw_data(game.ui_layer.colorbuffer.buf),
        i32(game.ui_layer.colorbuffer.width) * 4
    )
    sdl2.UpdateTexture(
        game.world_layer.colorbuffer.texture,
        nil,
        raw_data(game.world_layer.colorbuffer.buf),
        i32(game.world_layer.colorbuffer.width) * 4
    )
    // Render buffer textures
    sdl2.SetRenderTarget(game.renderer, game.render_texture)
    sdl2.SetRenderDrawColor(game.renderer, 50, 50, 50, 0xff)
    sdl2.RenderClear(game.renderer)
    sdl2.RenderCopy(game.renderer, game.world_layer.colorbuffer.texture, nil, nil)
    sdl2.RenderCopy(game.renderer, game.ui_layer.colorbuffer.texture, nil, nil) 
    sdl2.SetRenderTarget(game.renderer, nil)
    sdl2.RenderCopy(game.renderer, game.render_texture, nil, nil)
    sdl2.RenderPresent(game.renderer)
}

exit :: proc(game: ^Game) {
    for &entity in game.entities {
        entity_destroy(&entity)
    }
    terrain_destroy(game.terrain)
    delete(game.ui_layer.colorbuffer.buf)
    delete(game.ui_layer.drawn_areas.rects)
    delete(game.world_layer.colorbuffer.buf)
    delete(game.world_layer.depthbuffer.buf)
    delete(game.entities)
    sdl2.DestroyWindow(game.window)
    sdl2.Quit()
}

