shader_type spatial;
render_mode unshaded, skip_vertex_transform;

// Controls how strong the blur is
uniform float blur_strength : hint_range(0.0, 10.0) = 2.0;

void fragment() {
    // Use the object’s UV coordinates. (This example assumes your mesh uses UVs.)
    vec2 uv = UV;
    vec3 col = vec3(0.0);
    float total = 0.0;
    
    // Sample neighboring texels with small offsets.
    // (This is a simple 3x3 average; you can extend this for a higher-quality blur.)
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 offset = vec2(float(x), float(y)) * blur_strength * 0.001; // The scale factor here is empirical.
            col += texture(TEXTURE, uv + offset).rgb;
            total += 1.0;
        }
    }
    ALBEDO = col / total;
}
