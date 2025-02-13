shader_type spatial;
render_mode world_vertex_coords, specular_toon, diffuse_toon, skip_vertex_transform;

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
varying vec3 world_position;
varying vec3 world_normal;

// A small constant to avoid division by zero
const float EPSILON = 0.0001;

float calculate_biome_score(int biome_index, float height, float humidity, float temperature) {
    float score = 0.0;

    // Convert height from 0-1 to min_height-max_height
    height = mix(min_height, max_height, height);

    // --- Height Scoring ---
    float height_center = (height_ranges[biome_index].x + height_ranges[biome_index].y) * 0.5;
    float height_range = (height_ranges[biome_index].y - height_ranges[biome_index].x) * 0.5;
    float safe_height_range = max(height_range, EPSILON);
    float height_diff = abs(height - height_center);
    float height_base_score = 1.0 - (height_diff / safe_height_range);

    if (height_diff <= safe_height_range) {
        // In-range: apply inverse range weighting
        float height_weight = 1.0 / safe_height_range;
        score += height_base_score * height_weight;
    } else {
        // Out-of-range: apply a constant penalty (as in your original code)
        score += height_base_score * 2000.0;
    }

    // --- Humidity Scoring ---
    float humidity_center = (humidity_ranges[biome_index].x + humidity_ranges[biome_index].y) * 0.5;
    float humidity_range = (humidity_ranges[biome_index].y - humidity_ranges[biome_index].x) * 0.5;
    float safe_humidity_range = max(humidity_range, EPSILON);
    float humidity_diff = abs(humidity - humidity_center);
    float humidity_base_score = 1.0 - (humidity_diff / safe_humidity_range);

    if (humidity_diff <= safe_humidity_range) {
        float humidity_weight = 1.0 / safe_humidity_range;
        score += humidity_base_score * humidity_weight;
    } else {
        score += humidity_base_score * 2.0;
    }

    // --- Temperature Scoring ---
    float temperature_center = (temperature_ranges[biome_index].x + temperature_ranges[biome_index].y) * 0.5;
    float temperature_range = (temperature_ranges[biome_index].y - temperature_ranges[biome_index].x) * 0.5;
    float safe_temperature_range = max(temperature_range, EPSILON);
    float temperature_diff = abs(temperature - temperature_center);
    float temperature_base_score = 1.0 - (temperature_diff / safe_temperature_range);

    if (temperature_diff <= safe_temperature_range) {
        float temperature_weight = 1.0 / safe_temperature_range;
        score += temperature_base_score * temperature_weight;
    } else {
        score += temperature_base_score * 2.0;
    }

    return score;
}

void vertex() {
    VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = NORMAL;
    NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);

    noise_values1 = CUSTOM0.rgb;
    noise_values2 = CUSTOM1.rgb;
    world_position = VERTEX;
}

void fragment() {
    vec3 local_normal = normalize(cross(dFdy(world_position), dFdx(world_position)));

    mat3 model_matrix_inverse_transpose = inverse(transpose(mat3(MODEL_MATRIX)));
    vec3 world_space_normal = normalize(model_matrix_inverse_transpose * local_normal);
    vec3 view_space_normal = normalize(mat3(VIEW_MATRIX) * world_space_normal);

    float height      = noise_values1.r;
    float humidity    = noise_values1.g;
    float temperature = noise_values1.b;

    // Find the best matching biome based on the weighted scores
    float best_score = -1.0;
    int best_biome = 0;

    for (int i = 0; i < biome_count; i++) {
        float current_score = calculate_biome_score(i, height, humidity, temperature);
        if (current_score > best_score) {
            best_score = current_score;
            best_biome = i;
        }
    }

    // Set the final color based on the best matching biome
    ALBEDO = biome_colors[best_biome];
    BACKLIGHT = vec3(1.0);
}
