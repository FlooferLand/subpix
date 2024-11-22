shader_type canvas_item;

uniform sampler2D source_texture : filter_nearest;
uniform vec2 texture_size = vec2(32, 32);
uniform float grid_size = 32;

void fragment() {
    vec2 uv = UV;
    vec2 grid_uv = floor(uv * texture_size / grid_size);
    vec2 tex_uv = grid_uv / texture_size;
    vec4 pixel_color = texture(source_texture, tex_uv);
    COLOR = pixel_color;
}
