package main

import "core:log"
import "core:math"
import "vendor:sdl2"

import "core:fmt"
import "core:image"
import "core:image/png"

// Constants
WINDOW_TITLE :: "Voxel"
WINDOW_WIDTH :: 1920
WINDOW_HEIGHT :: 1080
RENDER_WIDTH :: 480
RENDER_HEIGHT :: 270
WINDOW_FLAGS :: sdl2.WindowFlags{.SHOWN}
TERRAIN_SIZE :: 1024
SCALE_FACTOR :f32: 100
CAM_SPEED :f32: 5.0
COLORMAP_PATH :: "./terrain/color.png"
HEIGHTMAP_PATH :: "./terrain/height.png"
PLAYER_SPRITE :: "./guy.png"
TRANSPARENT_COLOR :: 0xff00eb

// Program entry-point
main :: proc() {
    context.logger = log.create_console_logger()
    game := Game{ running = true, camera = &Camera{ x = 512, y = 512, z = 300, rot = math.PI * 1.5, tilt = -50, clip = 600 }, terrain = &Terrain{} }
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
