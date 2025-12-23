package main

import "core:fmt"
import "core:image"
import "core:math"

Entity :: struct {
    x: f32,
    y: f32,
    render_x: f32,
    render_y: f32,
    lerp_pos: f32,
    lerp_start_x: f32,
    lerp_start_y: f32,
    sprite: ^image.Image,
}

entities_destroy :: proc(entities: ^[dynamic]Entity) {
    for &entity in entities {
        entity_destroy(&entity)
    }
}

entities_update :: proc(entities: ^[dynamic]Entity) {
    for &entity in entities {
        entity_update(&entity)
    }
}

entities_render :: proc(world_layer: ^World_Layer, terrains: ^[9]Terrain, camera: ^Camera, entities: ^[dynamic]Entity) {
    for &entity in entities {
        entity_render(world_layer, terrains, camera, &entity)
    }
}

entity_new :: proc(entities: ^[dynamic]Entity, terrain: ^Terrain, x, y: f32) {
    img := img_load("./assets/guy.png")
    world_x, world_y := terrain_local_to_world(terrain, x, y)
    append(entities, Entity{ x = world_x, render_x = world_x, y = world_y, render_y = world_y, sprite = img })
}

entity_destroy :: proc(entity: ^Entity) {
    image.destroy(entity.sprite)
}

entity_move :: proc(terrains: ^[9]Terrain, camera: ^Camera, entity: ^Entity, dx, dy: f32) {
    entity.lerp_start_x = entity.x
    entity.lerp_start_y = entity.y
    entity.x += dx
    entity.y += dy
    entity.lerp_pos = 1
}

entity_update :: proc(entity: ^Entity) {
    if entity.lerp_pos > 0.01 {
        entity.lerp_pos = math.max(entity.lerp_pos - 0.1, 0.0)
        entity.render_x = lerp(entity.lerp_pos, entity.x, entity.lerp_start_x)
        entity.render_y = lerp(entity.lerp_pos, entity.y, entity.lerp_start_y)
    }
}

entity_render :: proc(world_layer: ^World_Layer, terrains: ^[9]Terrain, camera: ^Camera, entity: ^Entity) {
    x_min := min(min(camera.x, camera.x + camera.plx), camera.x + camera.prx)
    x_max := max(max(camera.x, camera.x + camera.plx), camera.x + camera.prx)
    y_min := min(min(camera.y, camera.y + camera.ply), camera.y + camera.pry)
    y_max := max(max(camera.y, camera.y + camera.ply), camera.y + camera.pry)
    if entity.render_x > x_min && entity.render_x < x_max && entity.render_y > y_min && entity.render_y < y_max {
        depth  := dot(entity.render_x - camera.x, entity.render_y - camera.y, camera.plx + camera.prx, camera.ply + camera.pry) / mag(camera.plx + camera.prx, camera.ply + camera.pry)
        if depth > 1.0 {
            draw_img_at_depth(
                world_layer,
                entity.sprite,
                int(math.round_f32((WORLD_RENDER_WIDTH * (CAM_CLIP * (entity.render_x - camera.chunk_x) - depth * camera.plx)) / (depth * (camera.prx - camera.plx)))),
                int(math.round_f32((camera.z - f32(terrain_height_at(terrain_at_world_space(terrains, entity.render_x, entity.render_y)) + ENTITY_GROUND_OFFSET)) / depth * TERRAIN_SCALE + camera.tilt)),
                depth
            )
        }
    }
}
