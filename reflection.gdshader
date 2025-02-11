shader_type spatial;

uniform sampler2D camera_texture : source_color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = texture(camera_texture, vec2(UV.x, 1.0 - UV.y)).rgb;
}
