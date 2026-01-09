#include <stddef.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include "dos/dos.h"

#define SCREEN_WIDTH 320
#define SCREEN_HEIGHT 200
#define MAP_N 1024
#define SCALE_FACTOR 70.0

uint8_t* heightmap = NULL;
uint8_t* colormap = NULL;

typedef struct {
    float x;       // x position on the map
    float y;       // y position on the map
    float height;  // height from sea level
    float angle;   // clockwise horizontal rotation angle in radians
    float horizon; // pitch up/down
    //float tilt;    // tilt/lean left right
    float zfar;    // max render distance
} camera_t;

camera_t camera = {
    .x       = 512.0,
    .y       = 512.0,
    .height  = 100.0,
    .angle   = 1.5 * 3.141592,
    .horizon = 75.0,
    //.tilt    = 0.0,
    .zfar    = 1000.0
};

void processinput() {
    if (keystate(KEY_W)) {
        camera.x += cos(camera.angle);
        camera.y += sin(camera.angle);
    }
    if (keystate(KEY_S)) {
        camera.x -= cos(camera.angle);
        camera.y -= sin(camera.angle);
    }
    if (keystate(KEY_A)) {
        camera.angle -= 0.01;
        //camera.tilt = 0.04;

    }
    if (keystate(KEY_D)) {
        camera.angle += 0.01;
        //camera.tilt = -0.04;
    }
    
    //float min_tilt = -0.5;
    //float max_tilt = 0.5;
    //float tilt_factor = 0.5;
    //camera.tilt = min_tilt + (tilt_factor * (max_tilt - min_tilt));

    if (keystate(KEY_E)) {
        camera.height++;
    }
    if (keystate(KEY_Q)) {
        camera.height--;
    }
    if (keystate(KEY_UP)) {
        camera.horizon += 1.5;
    }
    if (keystate(KEY_DOWN)) {
        camera.horizon -= 1.5;
    }
}

int main(int argc, char* args[]) {
    setvideomode(videomode_320x200);

    uint8_t palette[256 * 3];
    int pal_count;

    colormap = loadgif("assets/color.gif", NULL, NULL, &pal_count, palette);
    heightmap  = loadgif("assets/height.gif", NULL, NULL, NULL, NULL);


    for (int i = 0; i < pal_count; i++) {
        setpal(i, palette[3 * i + 0], palette[3 * i + 1], palette[3 * i + 2]);
    }

    //setpal(0, 36, 36, 56);
    
    setdoublebuffer(1);

    uint8_t* framebuffer = screenbuffer();

    while (!shuttingdown()) {
        waitvbl();
        clearscreen();
        processinput();

        float sinangle = sin(camera.angle);
        float cosangle = cos(camera.angle);

        float plx = cosangle * camera.zfar + sinangle * camera.zfar;
        float ply = sinangle * camera.zfar - cosangle * camera.zfar;

        float prx = cosangle * camera.zfar - sinangle * camera.zfar;
        float pry = sinangle * camera.zfar + cosangle * camera.zfar;

        // Loop through the 320 rays from left to right
        for (int i = 0; i < SCREEN_WIDTH; i++) {
            float delta_x = (plx + (prx - plx) / SCREEN_WIDTH * i) / camera.zfar;
            float delta_y = (ply + (pry - ply) / SCREEN_WIDTH * i) / camera.zfar;

            float rx = camera.x;
            float ry = camera.y;

            float max_height = SCREEN_HEIGHT;

            // Loop through the positions of the ray from camera to end-point on zfar
            for (int z = 1; z < camera.zfar; z++) {
                rx += delta_x;
                ry += delta_y;

                // Convert position to map position
                int mapoffset = ((1024 * ((int)(ry) & 1023)) + ((int)(rx) & 1023));

                int proj_height = (int)((camera.height - heightmap[mapoffset]) / z * SCALE_FACTOR + camera.horizon);

                if (proj_height < 0) {
                    proj_height = 0;
                }

                if (proj_height > SCREEN_HEIGHT) {
                    proj_height = SCREEN_HEIGHT - 1;
                }

                // Only render pixels if height is higher than previously rendered terrain at current x position
                if (proj_height < max_height) {

                    // tilt factor "lean" from -1 to +1
                    //float lean = (camera.tilt * (i / (float)SCREEN_WIDTH - 0.5) + 0.5) * SCREEN_HEIGHT / 6;
                    //for (int y = (proj_height + lean); y < (max_height + lean); y++) {
                    for (int y = proj_height; y < max_height; y++) {
                        if (y >= 0) {
                            framebuffer[(SCREEN_WIDTH * y) + i] = (uint8_t)colormap[mapoffset];
                        }
                    }
                    max_height = proj_height;
                }
            }

        }

        framebuffer = swapbuffers();

        if (keystate(KEY_ESCAPE))
            break;

    }

    return EXIT_SUCCESS;
}
