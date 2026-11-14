shader_type canvas_item;
// Per-sprite effects: hit flash to white, and Downscale into chunky blocks.
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float blocks : hint_range(1.0, 8.0) = 1.0;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 0.0);

void fragment() {
	vec2 tsize = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 uv = UV;
	if (blocks > 1.0) {
		uv = (floor(UV * tsize / blocks) + 0.5) * blocks / tsize;
	}
	vec4 c = texture(TEXTURE, uv);
	c.rgb = mix(c.rgb, tint.rgb, tint.a);
	c.rgb = mix(c.rgb, vec3(1.0), flash);
	COLOR = c * COLOR;
}
