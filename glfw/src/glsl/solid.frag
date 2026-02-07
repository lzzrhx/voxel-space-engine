#version 330 core

struct Material {
    float     shininess;
    vec3 color;
};

struct DirLight {
    vec3 dir;
    vec3 diffuse;
    vec3 specular;
};

struct PointLight {
    vec3  pos;
    vec3  diffuse;
    vec3  specular;
    float constant;
    float linear;
    float quadratic;
};

// Const
const int MAX_NUM_POINT_LIGHTS = 10;

// In
in vec3 vs_pos;
in vec3 vs_normal;
in vec2 vs_tex_coords;

// Uniform
uniform sampler2D terrain_depthbuf;
uniform vec3 ambient_light;
uniform vec3 view_pos;
uniform Material material;
uniform DirLight dir_light;
uniform PointLight lights[MAX_NUM_POINT_LIGHTS];
uniform int num_lights;
uniform float near_clip;
uniform float far_clip;
uniform vec2 window_size;

// Out
out vec4 out_frag_color;

void main()
{
    float depth = (2.0 * near_clip * far_clip) / (far_clip + near_clip - (gl_FragCoord.z * 2.0 - 1.0) * (far_clip - near_clip)) / far_clip;
    float terrain_depth = texture(terrain_depthbuf, vec2(gl_FragCoord.x / window_size.x, 1.0 - gl_FragCoord.y / window_size.y)).r;
    if (depth > terrain_depth) { discard; }
    vec3 normal = normalize(vs_normal);
    vec3 view_dir = normalize(view_pos - vs_pos);
    vec3 diff_color = material.color;
    vec3 spec_light = vec3(0.0);
    vec3 diff_light = ambient_light;
    { // Directional light
        vec3 light_dir = normalize(-dir_light.dir);
        vec3 reflect_dir = normalize(light_dir + view_dir);
        diff_light += dir_light.diffuse * max(dot(normal, light_dir), 0.0);
        spec_light += dir_light.specular * pow(max(dot(view_dir, reflect_dir), 0.0), material.shininess);
    }
    // Point light(s)
    for (int i = 0; i < num_lights; i++) {
        PointLight light = lights[i];
        vec3 light_dir = normalize(light.pos - vs_pos);
        vec3 reflect_dir = normalize(light_dir + view_dir);
        float distance = length(light.pos - vs_pos);
        float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));
        diff_light += max(vec3(0.0), attenuation * (light.diffuse * max(dot(normal, light_dir), 0.0)));
        spec_light += max(vec3(0.0), attenuation * (light.specular * pow(max(dot(view_dir, reflect_dir), 0.0), material.shininess)));
    }
    out_frag_color = vec4((diff_light * diff_color + spec_light * vec3(1.0)), 1.0);
}

