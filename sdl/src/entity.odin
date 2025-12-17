package main

import "core:fmt"
import "core:image"

Entity :: struct {
    x: int,
    y: int,
    sprite: ^image.Image,
}

entity_new :: proc(entities: ^[dynamic]Entity, x, y: int) {
    img := img_load(PLAYER_SPRITE)
    append(entities, Entity{x = x, y = y, sprite = img})
}

entity_destroy :: proc(entity: ^Entity) {
    image.destroy(entity.sprite)
}

entities_render :: proc(colorbuffer: []u32, depthbuffer: []u16, camera: ^Camera, terrain: ^Terrain, entities: ^[dynamic]Entity) {
    for entity in entities {
        if f32(entity.x) >= camera.x + camera.plx && f32(entity.x) <= camera.x + camera.prx && f32(entity.y) <= camera.y && f32(entity.y) >= camera.y + camera.ply {
            depth := camera.y - f32(entity.y)
            x := RENDER_WIDTH * 0.5 * (1 + (f32(entity.x) - camera.x) / depth)
            z := int((camera.z - f32(terrain_height_at(terrain, entity.x, entity.y) + 1.0)) / depth * SCALE_FACTOR + camera.tilt)
            draw_img_at_depth(colorbuffer, depthbuffer, entity.sprite, int(x), int(z), depth)
        }
    }
}
