shader_type canvas_item;

uniform sampler2D tile;
uniform float tile_size = 1.0;
uniform float brightness = 1.0;

void fragment() {
	vec2 tex_size = vec2(16, 16);
    float aspect_ratio = tex_size.x / tex_size.y;
    vec2 uv = mod(UV * vec2((tile_size * 2.0) * aspect_ratio, tile_size), 1.0);
	uv += TIME * -0.3;
	uv = mod(uv, 1.0);

	COLOR.rgb = texture(tile, uv).rgb * brightness;
}