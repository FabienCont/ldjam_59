shader_type canvas_item;

uniform sampler2D overlay: repeat_enable, filter_nearest;
uniform vec4 fg_color : source_color;
uniform vec4 bg_color : source_color;
uniform float tolerance : hint_range(0, 1);
uniform float tile_size = 16.0;

// Wave motion
uniform float wave_speed : hint_range(0.0, 5.0) = 1.0;
uniform float wave_strength : hint_range(0.0, 0.1) = 0.02;
uniform float wave_frequency : hint_range(0.0, 20.0) = 6.0;

// Water color
uniform vec4 water_shallow_color : source_color = vec4(0.3, 0.7, 1.0, 1.0);
uniform vec4 water_deep_color : source_color = vec4(0.05, 0.2, 0.5, 1.0);
uniform float color_blend : hint_range(0.0, 1.0) = 0.4;

// Edge foam
uniform sampler2D gradient_edge_texture: filter_nearest;
uniform float foam_edge_width : hint_range(0.0, 1.0) = 0.35;
uniform float foam_pulse_speed : hint_range(0.0, 5.0) = 1.0;
uniform float foam_pulse_strength : hint_range(0.0, 0.3) = 0.1;
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 curr_color = texture(TEXTURE, UV);

	float dist_bg = distance(curr_color.rgb, bg_color.rgb);
	float dist_fg = distance(curr_color.rgb, fg_color.rgb);

	if (dist_bg <= tolerance) {
		// Background pixel — draw 1px foam border if adjacent to water
		vec2 texel = 1.0 / vec2(textureSize(TEXTURE, 0));
		bool near_fg =
			distance(texture(TEXTURE, UV + vec2( texel.x, 0.0)).rgb, fg_color.rgb) <= tolerance ||
			distance(texture(TEXTURE, UV + vec2(-texel.x, 0.0)).rgb, fg_color.rgb) <= tolerance ||
			distance(texture(TEXTURE, UV + vec2(0.0,  texel.y)).rgb, fg_color.rgb) <= tolerance ||
			distance(texture(TEXTURE, UV + vec2(0.0, -texel.y)).rgb, fg_color.rgb) <= tolerance;
		if (near_fg) {
			COLOR = foam_color;
		} else {
			discard;
		}
	} else if (dist_fg <= tolerance) {
		// Water pixel — animate waves and apply foam
		vec2 scaled_pos = world_position / tile_size;
		float t = TIME * wave_speed;

		vec2 wave = vec2(
			sin(scaled_pos.y * wave_frequency + t),
			cos(scaled_pos.x * wave_frequency + t * 0.7)
		) * wave_strength;

		vec4 overlay_col = texture(overlay, scaled_pos + wave);

		// Tint water using overlay luminance as depth
		float depth = dot(overlay_col.rgb, vec3(0.299, 0.587, 0.114));
		vec4 water_col = mix(water_shallow_color, water_deep_color, depth);
		vec4 result = mix(overlay_col, water_col, color_blend);

		// Edge foam from gradient texture (dark = near edge, bright = interior)
		float edge_dist = texture(gradient_edge_texture, UV).r;
		float pulse = foam_edge_width + sin(TIME * foam_pulse_speed) * foam_pulse_strength;
		float foam = smoothstep(pulse, pulse * 0.3, edge_dist);
		// Quantize to 4 discrete steps: 0.25, 0.5, 0.75, 1.0
		foam = ceil(foam * 4.0) * 0.25;
		// Guarantee solid foam for the closest pixels to the edge
		float min_foam = step(edge_dist, 1.0 / float(textureSize(gradient_edge_texture, 0).y));
		foam = max(foam, min_foam);
		result = mix(result, vec4(foam_color.rgb, result.a), foam * foam_color.a);

		COLOR = result;
	} else {
		discard;
	}
}