package main

import "core:log"
import "core:math"
import "core:os"
import "core:fmt"
import "vendor:sdl2"
import "base:runtime"

Game :: struct {
    running: bool,
    ui_layer: ^Ui_Layer,
    world_layer: ^World_Layer,
    camera: ^Camera,
    terrains: ^[9]Terrain,
    entities: [dynamic]Entity,
    player: ^Entity,
    window: ^sdl2.Window,
    renderer: ^sdl2.Renderer,
    render_texture: ^sdl2.Texture,
    keystate: [^]u8,
    frame: u32,
    time: u32,
    prev_time: u32,
    dt: f64,
    fps: int,
    player_control: bool,
}

Ui_Layer :: struct {
    colorbuffer: ^Colorbuffer,
    drawn_areas: ^Collection(Rect, UI_MAX_DRAWS),
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
    terrain_load(&game.terrains[0], 0, 0)
    terrain_load(&game.terrains[1], 1, 0)
    terrain_load(&game.terrains[2], 2, 0)
    terrain_load(&game.terrains[3], 0, 1)
    terrain_load(&game.terrains[4], 1, 1, "./assets/terrain/color.png", "./assets/terrain/height.png")
    terrain_load(&game.terrains[5], 2, 1)
    terrain_load(&game.terrains[6], 0, 2)
    terrain_load(&game.terrains[7], 1, 2)
    terrain_load(&game.terrains[8], 2, 2)
    entity_new(&game.entities, &game.terrains[4], TILE_SIZE * 32, TILE_SIZE * 32)
    game.player = &game.entities[0]
    camera_set(game.terrains, game.camera, x = game.player.x, y = game.player.y)
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
    game.renderer = sdl2.CreateRenderer(game.window, -1, RENDERER_FLAGS)
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
            case .F: game.player_control = !game.player_control
            case .UP: if game.player_control {entity_move(game.terrains, game.camera, game.player,0,-TILE_SIZE)}
            case .DOWN: if game.player_control {entity_move(game.terrains, game.camera, game.player,0,TILE_SIZE)}
            case .LEFT: if game.player_control {entity_move(game.terrains, game.camera, game.player,-TILE_SIZE,0)}
            case .RIGHT: if game.player_control {entity_move(game.terrains, game.camera, game.player,TILE_SIZE,0)}
            }
        }
    }
    if !game.player_control {
        if game.keystate[sdl2.SCANCODE_UP] == 1 { camera_modify(game.terrains, game.camera, dx = math.cos_f32(game.camera.rot) * CAM_SPEED, dy = math.sin_f32(game.camera.rot) * CAM_SPEED) }
        if game.keystate[sdl2.SCANCODE_DOWN] == 1 { camera_modify(game.terrains, game.camera, dx = -math.cos_f32(game.camera.rot) * CAM_SPEED, dy = -math.sin_f32(game.camera.rot) * CAM_SPEED) }
        if game.keystate[sdl2.SCANCODE_LEFT] == 1 { camera_modify(game.terrains, game.camera, dx = math.sin_f32(game.camera.rot) * CAM_SPEED, dy = -math.cos_f32(game.camera.rot) * CAM_SPEED) }
        if game.keystate[sdl2.SCANCODE_RIGHT] == 1 { camera_modify(game.terrains, game.camera, dx = -math.sin_f32(game.camera.rot) * CAM_SPEED, dy = math.cos_f32(game.camera.rot) * CAM_SPEED) }
    }
    if game.keystate[sdl2.SCANCODE_W] == 1 { camera_modify(game.terrains, game.camera, dz = 3) }
    if game.keystate[sdl2.SCANCODE_S] == 1 { camera_modify(game.terrains, game.camera, dz = -3) }
    if game.keystate[sdl2.SCANCODE_A] == 1 { camera_modify(game.terrains, game.camera, drot = 0.02) }
    if game.keystate[sdl2.SCANCODE_D] == 1 { camera_modify(game.terrains, game.camera, drot = -0.02) }
    if game.keystate[sdl2.SCANCODE_Q] == 1 { camera_modify(game.terrains, game.camera, ddist = 2) }
    if game.keystate[sdl2.SCANCODE_E] == 1 { camera_modify(game.terrains, game.camera, ddist = -2) }
}

update :: proc(game: ^Game) {
    game.time = sdl2.GetTicks()
    game.dt = f64(game.time - game.prev_time)
    if game.dt > 0.0 && game.frame % 30 == 0 { game.fps = int(1000.0 / game.dt) }
    game.dt /= 1000.0
    game.prev_time = game.time
    game.frame += 1
    entities_update(&game.entities)
    if game.player_control {camera_update(game.terrains, game.camera, game.player)}
}

draw :: proc(game: ^Game) {
    // Clear ui buffer
    if game.ui_layer.drawn_areas.num > 0 {
        for i in 0 ..< game.ui_layer.drawn_areas.num {
            area := game.ui_layer.drawn_areas.data[i]
            for x in area.x ..< area.x + area.width {
                for y in area.y ..< area.y + area.height {
                    game.ui_layer.colorbuffer.buf[x + y * game.ui_layer.colorbuffer.width] = 0x00_00_00_00
                }
            }
        }
        game.ui_layer.drawn_areas.num = 0
    }
    // Draw to buffers
    terrain_render(game.world_layer, game.camera, game.terrains)
    entities_render(game.world_layer, game.terrains, game.camera, &game.entities)
    draw_ui_int(game.ui_layer, game.fps, 1, 0, 0xff_00_ff_00)
    draw_ui_string(game.ui_layer, game.camera.txt, 1, game.ui_layer.colorbuffer.height-CHAR_HEIGHT, 0xff_ff_ff_ff)
    // Add distant dithered fog to world layer
    if game.camera.fog_end > 0 {
        for x in 0 ..< game.world_layer.colorbuffer.width {
            for y in game.camera.fog_start ..< game.camera.fog_end {
                i := x + y * game.world_layer.colorbuffer.width
                dist := int((f32(game.world_layer.depthbuffer.buf[i]) - CAM_FOG_START) / (CAM_CLIP - CAM_FOG_START) * DITHER_2_MAX)
                dither_val := 0
                if x % 2 == 0 && y % 2 == 0 { dither_val = DITHER_2_0_0 }
                else if x % 2 == 1 && y % 2 == 0 { dither_val = DITHER_2_1_0 }
                else if x % 2 == 0 && y % 2 == 1 { dither_val = DITHER_2_0_1 }
                else if x % 2 == 1 && y % 2 == 1 { dither_val = DITHER_2_1_1 }
                if dist > dither_val { game.world_layer.colorbuffer.buf[i] = COLOR_SKY }
            }
        }
    }
    // Update buffer textures
    sdl2.UpdateTexture(game.ui_layer.colorbuffer.texture, nil, raw_data(game.ui_layer.colorbuffer.buf), i32(game.ui_layer.colorbuffer.width) * 4)
    sdl2.UpdateTexture(game.world_layer.colorbuffer.texture, nil, raw_data(game.world_layer.colorbuffer.buf), i32(game.world_layer.colorbuffer.width) * 4)
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
    defer free(game.terrains)
    defer delete(game.entities)
    for &terrain in game.terrains {if &terrain != nil {terrain_destroy(&terrain)}}
    entities_destroy(&game.entities)
    delete(game.ui_layer.colorbuffer.buf)
    free(game.ui_layer.drawn_areas.data)
    delete(game.world_layer.colorbuffer.buf)
    delete(game.world_layer.depthbuffer.buf)
    sdl2.DestroyWindow(game.window)
    sdl2.Quit()
}
