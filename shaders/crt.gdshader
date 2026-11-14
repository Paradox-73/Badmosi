shader_type canvas_item;
// CRT look over the whole game, drawn at window resolution: a slight bulge,
// a dark gap between rows of game pixels, a faint RGB stripe mask, colour
// fringing and a vignette. rows is the game height in pixels.
uniform float rows = 216.0;
uniform float curve = 0.035;
uniform float scan = 0.38;
uniform float mask = 0.12;

void fragment() {
	vec2 c = UV * 2.0 - 1.0;
	c *= 1.0 + curve * dot(c, c);
	vec2 uv = c * 0.5 + 0.5;
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		float fringe = 0.35 / (rows * 16.0 / 9.0);
		vec3 col;
		col.r = texture(TEXTURE, uv + vec2(fringe, 0.0)).r;
		col.g = texture(TEXTURE, uv).g;
		col.b = texture(TEXTURE, uv - vec2(fringe, 0.0)).b;
		// Row gaps: brightest in the middle of each game pixel row.
		float f = abs(fract(uv.y * rows) - 0.5) * 2.0;
		col *= 1.0 - scan * f * f;
		// Phosphor stripes, one screen pixel each.
		int stripe = int(mod(FRAGCOORD.x, 3.0));
		vec3 m = vec3(1.0 - mask);
		m[stripe] = 1.0;
		col *= m;
		// Brighten to make up for the darkening, then vignette.
		col *= 1.25;
		float v = 1.0 - 0.35 * pow(length(c * vec2(0.9, 1.0)) * 0.72, 3.0);
		COLOR = vec4(col * v, 1.0);
	}
}
