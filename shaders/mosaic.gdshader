shader_type canvas_item;
// Screen mosaic used by room transitions, the F-it censor and the Admin's blur.
uniform float block : hint_range(1.0, 64.0) = 1.0;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;

void fragment() {
	vec2 size = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 p = floor(SCREEN_UV * size / block) * block + block * 0.5;
	COLOR = texture(screen_tex, p / size);
}
