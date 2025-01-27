shader_type spatial;
render_mode world_vertex_coords;

// Maximum number of biomes
const int MAX_BIOMES = 16;

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

varying vec3 noise_values1; // continentalness, erosion, peaks_valleys
varying vec3 noise_values2; // humidity, temperature, difficulty

float calculate_biome_score(int biome_index, float height, float humidity, float temperature) {
    float score = 0.0;

    // convert height from 0-1 to min_height-max_height
    height = mix(min_height, max_height, height);

    // Calculate score for height
    if (strict_height[biome_index]) {
        if (height >= height_ranges[biome_index].x && height <= height_ranges[biome_index].y) {
            score += 10.0;
        } else {
            score -= 10.0;
        }
    } else {
        float height_score = 1.0 - abs((height - height_ranges[biome_index].x) /
                                     (height_ranges[biome_index].y - height_ranges[biome_index].x));
        score += height_score;
    }

    // Calculate score for humidity
    float humidity_score = 1.0 - abs((humidity - humidity_ranges[biome_index].x) /
                                   (humidity_ranges[biome_index].y - humidity_ranges[biome_index].x));
    score += humidity_score;

    // Calculate score for temperature
    float temperature_score = 1.0 - abs((temperature - temperature_ranges[biome_index].x) /
                                      (temperature_ranges[biome_index].y - temperature_ranges[biome_index].x));
    score += temperature_score;

    // // Calculate score for difficulty
    // float difficulty_score = 1.0 - abs((difficulty - difficulty_ranges[biome_index].x) /
    //                                  (difficulty_ranges[biome_index].y - difficulty_ranges[biome_index].x));
    // score += difficulty_score;

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
    //float difficulty = noise_values2.r;

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
}
