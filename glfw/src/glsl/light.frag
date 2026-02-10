#version 330 core

// In
in vec4 vs_pos;

// Uniform
uniform float depth;
uniform float clip;
uniform vec3 color;

// Out
out vec4 fs_frag_color;

void main()
{
    gl_FragDepth = vs_pos.z / clip + depth;
    fs_frag_color = vec4(color, 1.0);
}

