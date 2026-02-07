#version 330 core

// In
in vec2 vs_tex_coords;

//Uniform
uniform vec3 diffuse;
uniform vec3 specular;

// Out
out vec4 out_frag_color;

void main()
{
    out_frag_color = vec4(mix(specular, diffuse, distance(abs(vs_tex_coords - 0.5) * 2, vec2(0))), 1.0);
}
