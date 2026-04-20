shader_type canvas_item;
uniform vec4 modulate_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
varying vec2 world_position;
void vertex() {
	
    world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 curr_color = texture(TEXTURE, UV);
	COLOR *= modulate_color;
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
