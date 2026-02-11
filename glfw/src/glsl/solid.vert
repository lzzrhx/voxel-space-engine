#version 330 core

// Structs
struct DirLight { vec3 dir; vec3 color;};
struct Light { vec2  pos; vec3  color; float constant; float linear; float quadratic; };

// Constants
const int MAX_NUM_LIGHTS = 10;

// In / Out
layout (location = 0) in vec3 in_pos;
layout (location = 1) in vec3 in_normal;
layout (location = 2) in vec2 in_tex_coords;
out vec3 vs_color;
out float vs_depth;

// Uniforms
uniform mat3 normal_mat;
uniform mat4 model_mat;
uniform mat4 pv_mat;
uniform vec3 ambient_light;
uniform DirLight dir_light;
uniform Light lights[MAX_NUM_LIGHTS];
uniform int num_lights;
uniform vec3 color;
uniform float clip;
uniform float tile_size;

void main() {
    gl_Position = pv_mat * model_mat * vec4(in_pos, 1.0);
    vs_depth = gl_Position.z / clip;
    vec2 world_pos = (model_mat * vec4(in_pos, 1.0)).xz;
    vec3 normal = normalize(normal_mat * in_normal);
    vec3 dir_light_dir = normalize(-dir_light.dir);
    vec3 light_sum = ambient_light + dir_light.color * max(dot(normal, dir_light_dir), 0.0);
    for (int i = 0; i < num_lights; i++) {
        Light light = lights[i];
        vec3 light_dir = vec3(normalize(light.pos - world_pos), 0.0).xzy;
        float distance = length(light.pos - world_pos) / tile_size;
        float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));
        light_sum += max(vec3(0.0), attenuation * (light.color * max(dot(normal, light_dir), 0.0)));
    }
    vs_color = light_sum * color;
}
