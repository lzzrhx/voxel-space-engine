#version 330 core

// In
in vec3 vs_pos;

const float scale = 300.0;
const float cell_size = 0.025;
const vec3 color_thin = vec3(0.5, 0.5, 0.5);
const vec3 color_thick = vec3(0.5, 0.5, 0.5);
const float min_pixels_between_cells = 2.0;

uniform vec2 center_pos;

// Out
out vec4 out_frag_color;

float log10(float x) {
    return log(x) / log(10.0);
}


float satf(float x) {
    return clamp(x, 0.0, 1.0);
}

float max2(vec2 v) {
    return max(v.x, v.y);
}

vec2 satv(vec2 x) {
    return clamp(x, vec2(0.0), vec2(1.0));
}

void main()
{
    vec2 dvx = vec2(dFdx(vs_pos.x), dFdy(vs_pos.x));
    vec2 dvy = vec2(dFdx(vs_pos.z), dFdy(vs_pos.z));
    float lx = length(dvx);
    float ly = length(dvy);
    vec2 dudv = vec2(lx, ly) * 4.0;
    float l = length(dudv);
    float lod = max(0.0, log10(l * min_pixels_between_cells / cell_size) + 1.0);
    float cell_size_lod0 = cell_size * pow(10.0, floor(lod));
    float cell_size_lod1 = cell_size_lod0 * 10.0;
    float cell_size_lod2 = cell_size_lod1 * 10.0;

    vec2 mod_div_dudv = mod(vs_pos.xz, cell_size_lod0) / dudv;
    float lod0a = max2(vec2(1.0) - abs(satv(mod_div_dudv) * 2.0 - vec2(1.0)));
    
    mod_div_dudv = mod(vs_pos.xz, cell_size_lod1) / dudv;
    float lod1a = max2(vec2(1.0) - abs(satv(mod_div_dudv) * 2.0 - vec2(1.0)));
    
    mod_div_dudv = mod(vs_pos.xz, cell_size_lod2) / dudv;
    float lod2a = max2(vec2(1.0) - abs(satv(mod_div_dudv) * 2.0 - vec2(1.0)));

    float lod_fade = fract(lod);
    vec4 color = vec4(color_thick, lod2a);

    if (lod2a <= 0.0) {
        if (lod1a > 0.0) {
            color = vec4(mix(color_thick, color_thin, lod_fade), lod1a);
        } else {
            color = vec4(color_thin, lod0a * (1.0 - lod_fade));
        }
    }

    color.a *= 1.0 - satf(length(vs_pos.xz - center_pos) / scale);

    out_frag_color = color;
}
