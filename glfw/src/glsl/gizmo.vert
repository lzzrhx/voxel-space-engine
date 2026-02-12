#version 330 core

// Constants
const vec3 coords[4] = vec3[4]( vec3(0.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 0.0, 1.0) );
const vec3 colors[3] = vec3[3]( vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 0.0, 1.0) );

// In / Out
out vec3 vs_color;

// Uniforms
uniform mat4 pv_mat;
uniform vec2 pos;
uniform vec2 rot;
const float length = 12.0;

void main() {
    vs_color = colors[gl_VertexID / 2];
    mat4 rot_y = mat4(1);
    rot_y[0][0] =  cos(rot.y);
    rot_y[2][0] =  sin(rot.y);
    rot_y[0][2] = -sin(rot.y);
    rot_y[2][2] =  cos(rot.y);
    mat4 rot_x = mat4(1);
    rot_x[1][1] =  cos(rot.x);
    rot_x[2][1] = -sin(rot.x);
    rot_x[1][2] =  sin(rot.x);
    rot_x[2][2] =  cos(rot.x);
    mat4 trans_mat = mat4(1);
    trans_mat[3][0] = pos.x;
    trans_mat[3][2] = pos.y;
    mat4 model_mat = trans_mat * rot_y;
    gl_Position = pv_mat * model_mat * vec4(coords[(gl_VertexID / 2 + 1) * (gl_VertexID % 2)] * length, 1.0);
}
