package main

import "core:fmt"
import "core:log"
import "core:os"
import "core:image/png"
import "vendor:sdl2"
import "core:image"

// Constants
WINDOW_TITLE :: "Voxel"
WINDOW_WIDTH :: 640
WINDOW_HEIGHT :: 400
WINDOW_FLAGS :: sdl2.WindowFlags{.SHOWN}

TERRAIN_SIZE :: 1024
SCALE_FACTOR :: 100

COLORMAP_PATH :: "color.png"
HEIGHTMAP_PATH :: "height.png"

Camera :: struct {
    x: f32,
    y: f32,
    z: f32,
    clip: f32,
    rot: f32,
    plx: f32,
    ply: f32,
    prx: f32,
    pry: f32,
}
cam := Camera{ x = 512, y = 512, z = 150, clip = 400 }

Game :: struct {
    running: bool,
    window: ^sdl2.Window,
    renderer: ^sdl2.Renderer,
    render_texture: ^sdl2.Texture,
    color_buffer: ^[WINDOW_HEIGHT * WINDOW_WIDTH]u32,
    terrain_color: ^image.Image,
    terrain_height: ^image.Image,
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
            case .LEFT:
                cam.x -= 1
            case .RIGHT:
                cam.x += 1
            case .UP:
                cam.y += 1
            case .DOWN:
                cam.y -= 1
            }
        }
    }
}

// Update things
update :: proc() {
    cam.plx = -cam.clip
    cam.ply = cam.clip
    cam.prx = cam.clip
    cam.pry = cam.clip
}

// Render the color buffer
render :: proc() {
    sdl2.SetRenderDrawColor(game.renderer, 50, 50, 50, 0xff)
    sdl2.RenderClear(game.renderer)    
    for i := 0; i < WINDOW_HEIGHT * WINDOW_WIDTH; i+=1 {
        game.color_buffer[i] = 0x000000
    }
    render_terrain()
    sdl2.UpdateTexture(
        game.render_texture,
        nil,
        raw_data(game.color_buffer),
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

img_load :: proc(path: string) -> ^image.Image {
    img,img_err := image.load(path, image.Options{.return_metadata})
    if img_err != nil {
        log.errorf("Couldn't load %v.", path)
        os.exit(1)
    } else {
        fmt.printf("Loaded image %v: %vx%vx%v, %v-bit.\n", path, img.width, img.height, img.channels, img.depth)
    }
    return img
}

img_color_at :: proc(img: ^image.Image, i: int) -> (u32) {
    return u32(img.pixels.buf[i]) | u32(img.pixels.buf[i+1]) << 8 | u32(img.pixels.buf[i+2]) << 16
}

render_terrain :: proc() {
    for x in 0 ..< WINDOW_WIDTH {
        dx: f32 = (cam.plx + (cam.prx - cam.plx) / f32(WINDOW_WIDTH) * f32(x)) / cam.clip
        dy: f32 = (cam.ply + (cam.pry - cam.ply) / f32(WINDOW_WIDTH) * f32(x)) / cam.clip
        rx := cam.x
        ry := cam.y
        max_height: int = WINDOW_HEIGHT
        for z in 1 ..< cam.clip {
            rx += dx
            ry += dy
            i: int = (int(rx) & (TERRAIN_SIZE-1)) + (int(ry) & (TERRAIN_SIZE-1)) * TERRAIN_SIZE
            height: int = int((cam.z - f32(game.terrain_height.pixels.buf[i*3])) / f32(z) * f32(SCALE_FACTOR))
            if height < 0 {
                height = 0
            }
            if height > WINDOW_HEIGHT {
                height = WINDOW_HEIGHT - 1
            }
            if height < max_height {
                for y in height ..< max_height {
                    game.color_buffer[int(x + y * WINDOW_WIDTH)] = img_color_at(game.terrain_color, i*4)
                }
                max_height = height
            }
        }
    }
}

// Program entry-point
main :: proc() {
    context.logger = log.create_console_logger()
    // Initialization
    if ok := init_sdl(); !ok {
        log.errorf("SDL initialization failed.")
        os.exit(1)
    }
    // Set up colorbuffer
    game.color_buffer = new([WINDOW_HEIGHT * WINDOW_WIDTH]u32)
    defer free(game.color_buffer)
    game.terrain_color = img_load(COLORMAP_PATH)
    defer image.destroy(game.terrain_color)
    game.terrain_height = img_load(HEIGHTMAP_PATH)
    defer image.destroy(game.terrain_height)

    //fmt.println(len(img.pixels.buf))
    //for i := 0; i+2 < len(img.pixels.buf); i+=3 {
    //r := img.pixels.buf[i]
    //g := img.pixels.buf[i+1]
    //b := img.pixels.buf[i+2]
    //}

    // Main loop
    game.frame_start = f64(sdl2.GetPerformanceCounter()) / f64(sdl2.GetPerformanceFrequency())
    for game.running {
        input()
        update()
        render()
        game.frame_end = f64(sdl2.GetPerformanceCounter()) / f64(sdl2.GetPerformanceFrequency())
        game.frame_elapsed = game.frame_end - game.frame_start
        game.frame_start = game.frame_end
    }
    // Execution finished
    defer exit()
}
