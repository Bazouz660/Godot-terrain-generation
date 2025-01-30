#[compute]
#version 450

layout(local_size_x = 4, local_size_y = 4, local_size_z = 1) in;

struct Params {
    vec2 grid_position;
    float chunk_size;
    float cell_size;
    float vertex_count;
    float vertex_per_meter;
    float seed;
    float max_features;
};

struct FeatureParam {
    float density;
    float biome_id;
    float feature_index;
};

layout(set = 0, binding = 0, std430) restrict buffer ParamsBuffer {
    Params params;
};

layout(set = 0, binding = 1, std430) restrict buffer BiomeBuffer {
    int data[];
} biome_buffer;

layout(set = 0, binding = 2, std430) restrict buffer HeightBuffer {
    float data[];
} height_buffer;

layout(set = 0, binding = 3, std430) restrict buffer FeatureParamsBuffer {
    FeatureParam data[];
} feature_params;

layout(set = 0, binding = 4, std430) restrict buffer OutputBuffer {
    vec4 data[];
} output_buffer;

layout(set = 0, binding = 5, std430) restrict buffer CounterBuffer {
    uint feature_count;
    uint debug_cells_processed;
    uint debug_density_passed;
    uint debug_bounds_passed;
    uint debug_biome_matched;
};

float random(uint seed) {
    uint state = seed;
    state = state * 747796405u + 2891336453u;
    state = ((state >> ((state >> 28) + 4u)) ^ state) * 277803737u;
    state = (state >> 22) ^ state;
    return float(state) / 4294967295.0;
}

void main() {
    uvec2 cell = gl_GlobalInvocationID.xy;
    uint cells_per_side = uint(params.chunk_size / params.cell_size);

    // Early exit if outside chunk bounds
    if (cell.x >= cells_per_side || cell.y >= cells_per_side) {
        return;
    }

    // Increment cells processed counter
    atomicAdd(counter.debug_cells_processed, 1u);

    uint cell_index = cell.y * cells_per_side + cell.x;

    // Process each feature parameter
    for (int i = 0; i < 100; i++) {
        FeatureParam feature = feature_params.data[i];

        // Skip if density is 0
        if (feature.density <= 0.0) {
            continue;
        }

        // Calculate target features for this cell
        float cell_area = params.cell_size * params.cell_size;
        float target_density = feature.density * cell_area / 300.0;

        // Generate random value for feature placement
        uint feature_seed = uint(params.seed) + cell_index + uint(i) * 1000u;
        float rand_value = random(feature_seed);

        if (rand_value > target_density) {
            continue;
        }

        // Increment density passed counter
        atomicAdd(counter.debug_density_passed, 1u);

        // Generate position within cell
        float offset_x = random(feature_seed * 2u) * params.cell_size;
        float offset_z = random(feature_seed * 3u) * params.cell_size;

        // Calculate world position
        vec2 world_pos = vec2(
            params.grid_position.x * params.chunk_size + float(cell.x) * params.cell_size + offset_x,
            params.grid_position.y * params.chunk_size + float(cell.y) * params.cell_size + offset_z
        );

        // Get vertex coordinates
        ivec2 vertex = ivec2(world_pos * params.vertex_per_meter);

        // Check if vertex is within bounds
        if (vertex.x < 0 || vertex.x >= int(params.vertex_count) ||
            vertex.y < 0 || vertex.y >= int(params.vertex_count)) {
            continue;
        }

        // Increment bounds passed counter
        atomicAdd(counter.debug_bounds_passed, 1u);

        int vertex_index = int(vertex.y * params.vertex_count + vertex.x);

        // Check biome
        int biome = biome_buffer.data[vertex_index];
        if (biome != int(feature.biome_id)) {
            continue;
        }

        // Increment biome matched counter
        atomicAdd(counter.debug_biome_matched, 1u);

        // Get height
        float height = height_buffer.data[vertex_index];

        // Add feature position
        uint index = atomicAdd(feature_count, 1u);
        if (index < uint(params.max_features)) {
            float packed_key = feature.biome_id * 65536.0 + feature.feature_index;
            output_buffer.data[index] = vec4(world_pos.x, height, world_pos.y, packed_key);
        }
    }
}