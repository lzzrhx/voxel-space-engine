package main

import "core:log"
import "core:math"
import "vendor:sdl2"
import "core:mem"
import "core:fmt"

// Constants
WINDOW_TITLE              :: "Voxel"
WINDOW_FLAGS              :: sdl2.WindowFlags{.SHOWN}
WINDOW_WIDTH              :: 1920
WINDOW_HEIGHT             :: 1080
RENDERER_FLAGS            :: sdl2.RendererFlags{.ACCELERATED, .PRESENTVSYNC, .TARGETTEXTURE}
RENDER_WIDTH              :: 960
RENDER_HEIGHT             :: 540
WORLD_RENDER_WIDTH        :: 480
WORLD_RENDER_HEIGHT       :: 270
TRANSPARENT_COLOR         :: 0xff00eb
SPRITE_SIZE               :: 16
TILE_SIZE                 :: 16
UI_MAX_DRAWS              :: 100
ENTITY_GROUND_OFFSET      :: 1
COLOR_SKY                 :: 0x00_2c_17_01
SPRITE_SCALE              :: 0.75
TERRAIN_SIZE              :: 1024
TERRAIN_SCALE             :: 100.0
TERRAIN_DEFAULT_COLORMAP  :: "./assets/terrain/default-color.png"
TERRAIN_DEFAULT_HEIGHTMAP :: "./assets/terrain/default-height.png"
CAM_DIST_MIN           :f32: 100
CAM_DIST_MAX           :f32: 200
CAM_Z_MIN              :f32: 0
CAM_Z_MAX              :f32: 400
CAM_SPEED                 :: 3.0
CAM_CLIP                  :: 700
CAM_FOG_START             :: 500
CAM_HEIGHT_COLLISION      :: 10

// Program entry-point
main :: proc() {
    defer free_all(context.temp_allocator)
    context.logger = log.create_console_logger()
    // Tracking allocator set up
    tracking_allocator: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking_allocator, context.allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    defer mem_check_leaks(&tracking_allocator)
    // Game set up
    game := &Game{
        running = true,
        ui_layer = &Ui_Layer{
            colorbuffer = &Colorbuffer{ buf = new([RENDER_WIDTH * RENDER_HEIGHT]u32)[:], width = RENDER_WIDTH, height = RENDER_HEIGHT },
            drawn_areas = &Collection(Rect, UI_MAX_DRAWS){ data = new([UI_MAX_DRAWS]Rect) },
        },
        world_layer = &World_Layer{
            colorbuffer = &Colorbuffer{ buf = new([WORLD_RENDER_WIDTH * WORLD_RENDER_HEIGHT]u32)[:], width = WORLD_RENDER_WIDTH, height = WORLD_RENDER_HEIGHT },
            depthbuffer = &Depthbuffer{ buf = new([WORLD_RENDER_WIDTH * WORLD_RENDER_HEIGHT]u16)[:], width = WORLD_RENDER_WIDTH, height = WORLD_RENDER_HEIGHT },
        },
        camera = &Camera{},
        terrains = new([9]Terrain),
        entities = make([dynamic]Entity),
    }
    init(game)
    defer exit(game)
    for game.running {
        input(game)
        update(game)
        draw(game)
        mem_check_bad_free(&tracking_allocator)
    }
}
