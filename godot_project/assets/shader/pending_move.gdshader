shader_type canvas_item;

uniform float pulse_speed : hint_range(0.5, 5.0) = 2.0;
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.1) {
		discard;
	}
	float pulse = sin(TIME * pulse_speed) * 0.3 + 0.75;
	COLOR = vec4(tex.rgb * tint_color.rgb, tex.a) * pulse;
}
