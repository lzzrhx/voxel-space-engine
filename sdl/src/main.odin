package main

import "core:log"
import "vendor:sdl2"

// Constants
WINDOW_TITLE :: "Voxel"
WINDOW_WIDTH :: 1920
WINDOW_HEIGHT :: 1080
RENDER_WIDTH :: 480
RENDER_HEIGHT :: 270
WINDOW_FLAGS :: sdl2.WindowFlags{.SHOWN}
TERRAIN_SIZE :: 1024
SCALE_FACTOR :: 300
CAM_SPEED :f32: 5.0
COLORMAP_PATH :: "./terrain/color.png"
HEIGHTMAP_PATH :: "./terrain/height.png"

// Program entry-point
main :: proc() {
    context.logger = log.create_console_logger()
    game := Game{ running = true, camera = &Camera{ x = 512, y = 512, z = 100, tilt = -50, clip = 600 }, terrain = &Terrain{} }
    init(&game)
    defer exit(&game)
    time: u32
    prev_time: u32
    dt : f64
    fps : int
    frame : int
    for game.running {
        time = sdl2.GetTicks()
        dt = f64(time - prev_time)
        if dt > 0.0 && frame == 0 { fps = int(1000.0 / dt) }
        dt /= 1000.0
        prev_time = time
        frame = frame > 30 ? 0 : frame + 1
        input(&game)
        update(&game)
        draw(&game, fps)
    }
}
