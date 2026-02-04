package main
import "core:log"
import "core:os"
import stbi "vendor:stb/image"
import gl "vendor:OpenGL"


texture_load :: proc(filename: cstring, filtering: bool = true) -> u32 {
    texture_id: u32
    img_width, img_height, img_channels: i32
    gl.GenTextures(1, &texture_id)
    gl.BindTexture(gl.TEXTURE_2D, texture_id)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, filtering ? gl.LINEAR : gl.NEAREST)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, filtering ? gl.LINEAR : gl.NEAREST)
    img := stbi.load(filename, &img_width, &img_height, &img_channels, 0)
    if img == nil {
        log.errorf("Failed to load texture image.")
        os.exit(1)
    }
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, img_width, img_height, 0, img_channels == 4 ? gl.RGBA : (img_channels == 3 ? gl.RGB : gl.RED), gl.UNSIGNED_BYTE, img)
    gl.GenerateMipmap(gl.TEXTURE_2D)
    stbi.image_free(img)
    return texture_id
}
