package main

import "core:log"
import "vendor:sdl2"

// Constants
WINDOW_TITLE :: "Voxel"
WINDOW_WIDTH :: 960
WINDOW_HEIGHT :: 540
WINDOW_FLAGS :: sdl2.WindowFlags{.SHOWN}
FPS :u32: 60
MS_PER_FRAME :u32: 1000 / FPS
TERRAIN_SIZE :: 1024
SCALE_FACTOR :: 400
CAM_SPEED :f32: 5.0
COLORMAP_PATH :: "color.png"
HEIGHTMAP_PATH :: "height.png"

// Program entry-point
main :: proc() {
    context.logger = log.create_console_logger()
    game := Game{ running = true, camera = &Camera{ x = 512, y = 512, z = 150, tilt = 100, clip = 600 }, terrain = &Terrain{} }
    init(&game)
    defer exit(&game)
    //time: u32
    //prev_time: u32
    //wait_time: u32
    //dt : f64
    for game.running {
        //time = sdl2.GetTicks()
        //wait_time = MS_PER_FRAME - (time - prev_time)
        //if wait_time > 0 && wait_time <= MS_PER_FRAME { sdl2.Delay(wait_time) }
        //dt = f64(time - prev_time) / 1000.0
        //prev_time = time
        input(&game)
        update(&game)
        draw(&game)
    }
}
