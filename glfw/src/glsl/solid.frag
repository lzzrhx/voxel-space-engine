#version 330 core

// In
in vec3 vs_color;

// Uniform
uniform sampler2D terrain_depthbuf;
uniform vec2 window_size;
uniform float depth;

// Out
out vec4 fs_frag_color;

void main()
{
    float terrain_depth = texture(terrain_depthbuf, vec2(gl_FragCoord.x / window_size.x, 1.0 - gl_FragCoord.y / window_size.y)).r;
    if (depth > terrain_depth) { discard; }
    //gl_FragDepth = depth;
    fs_frag_color = vec4(vs_color, 1.0);
}

