shader_type spatial;
render_mode world_vertex_coords, specular_toon, diffuse_toon;

// Maximum number of biomes
const int MAX_BIOMES = 32;

// Biome data
uniform vec3 biome_colors[MAX_BIOMES];
uniform vec2 height_ranges[MAX_BIOMES];
uniform vec2 humidity_ranges[MAX_BIOMES];
uniform vec2 temperature_ranges[MAX_BIOMES];
uniform vec2 difficulty_ranges[MAX_BIOMES];
uniform bool strict_height[MAX_BIOMES];
uniform int biome_count;
uniform float max_height;
uniform float min_height;
uniform sampler2D gradient : source_color;

varying vec3 noise_values1; // continentalness, erosion, peaks_valleys
varying vec3 noise_values2; // humidity, temperature, difficulty

float calculate_biome_score(int biome_index, float height, float humidity, float temperature) {
    float score = 0.0;

    // convert height from 0-1 to min_height-max_height
    height = mix(min_height, max_height, height);

    // Calculate score for height
    float height_center = (height_ranges[biome_index].x + height_ranges[biome_index].y) * 0.5;
    float height_range = (height_ranges[biome_index].y - height_ranges[biome_index].x) * 0.5;
    float height_diff = abs(height - height_center);
    float height_score = 1.0 - (height_diff / height_range);
    if (height_score < 0.0) {
        height_score *= 2.0; // Double the penalty for being out of range
        if (strict_height[biome_index]) {
            height_score *= 10.0; // Double the penalty for being out of range
        }
    }
    score += height_score;

    // Calculate score for humidity
    float humidity_center = (humidity_ranges[biome_index].x + humidity_ranges[biome_index].y) * 0.5;
    float humidity_range = (humidity_ranges[biome_index].y - humidity_ranges[biome_index].x) * 0.5;
    float humidity_diff = abs(humidity - humidity_center);
    float humidity_score = 1.0 - (humidity_diff / humidity_range);
    if (humidity_score < 0.0) {
        humidity_score *= 2.0; // Double the penalty for being out of range
    }
    score += humidity_score;

    // Calculate score for temperature
    float temperature_center = (temperature_ranges[biome_index].x + temperature_ranges[biome_index].y) * 0.5;
    float temperature_range = (temperature_ranges[biome_index].y - temperature_ranges[biome_index].x) * 0.5;
    float temperature_diff = abs(temperature - temperature_center);
    float temperature_score = 1.0 - (temperature_diff / temperature_range);
    if (temperature_score < 0.0) {
        temperature_score *= 2.0; // Double the penalty for being out of range
    }
    score += temperature_score;

    return score;
}

void vertex() {
    noise_values1 = CUSTOM0.rgb;
    noise_values2 = CUSTOM1.rgb;
}

void fragment() {
    float height = noise_values1.r;
    float humidity = noise_values1.g;
    float temperature = noise_values1.b;

    // Find the best matching biome
    float best_score = -1.0;
    int best_biome = 0;

    for(int i = 0; i < biome_count; i++) {
        float score = calculate_biome_score(i, height, humidity, temperature);
        if(score > best_score) {
            best_score = score;
            best_biome = i;
        }
    }

    // Use the exact color of the best matching biome
    ALBEDO = biome_colors[best_biome];
	BACKLIGHT = vec3(1.0);
}