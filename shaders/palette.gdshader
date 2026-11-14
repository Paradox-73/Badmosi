shader_type canvas_item;
// Club palette: maps the screen's brightness onto four colours of the room's retro palette.
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec4 c0 : source_color = vec4(0.06, 0.05, 0.09, 1.0);
uniform vec4 c1 : source_color = vec4(0.25, 0.2, 0.35, 1.0);
uniform vec4 c2 : source_color = vec4(0.6, 0.5, 0.7, 1.0);
uniform vec4 c3 : source_color = vec4(0.95, 0.94, 0.9, 1.0);
uniform float amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 src = texture(screen_tex, SCREEN_UV);
	float l = dot(src.rgb, vec3(0.299, 0.587, 0.114));
	vec3 m = l < 0.25 ? c0.rgb : (l < 0.5 ? c1.rgb : (l < 0.75 ? c2.rgb : c3.rgb));
	COLOR = vec4(mix(src.rgb, m, amount), 1.0);
}
