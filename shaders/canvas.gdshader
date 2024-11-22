shader_type canvas_item;

uniform sampler2D source_texture : filter_nearest;
uniform vec2 texture_size = vec2(32, 32);
uniform vec2 grid_size = vec2(32, 32);
uniform float border_thickness = 0.1;

void fragment() {
	// Get the UV coordinates for this fragment
    vec2 uv = UV;

    // Map UV coordinates to the pixel grid
    vec2 pixel_uv = floor(uv * texture_size);

    // Normalize pixel_uv back to UV space for sampling
    vec2 tex_uv = pixel_uv / texture_size;

    // Sample the texture color at the computed tex_uv
    vec4 pixel_color = texture(source_texture, tex_uv);

    // Determine the subpixel (R, G, or B) based on the horizontal position
    float subpixel_width = 1.0 / (3.0 * texture_size.x); // Width of one subpixel in UV space
    float x_in_pixel = mod(uv.x, 1.0 / texture_size.x);  // Position within the current pixel in UV space

    // Assign color based on the subpixel
    if (x_in_pixel < subpixel_width) {
        // Red subpixel
        COLOR = vec4(pixel_color.r, 0.0, 0.0, 1.0);
    } else if (x_in_pixel < 2.0 * subpixel_width) {
        // Green subpixel
        COLOR = vec4(0.0, pixel_color.g, 0.0, 1.0);
    } else {
        // Blue subpixel
        COLOR = vec4(0.0, 0.0, pixel_color.b, 1.0);
    }
}
