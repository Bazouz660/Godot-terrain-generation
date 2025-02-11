shader_type spatial;
render_mode unshaded, blend_premul_alpha;

uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D normal_roughness_texture : hint_normal_roughness_texture, repeat_disable, filter_nearest;
uniform sampler2D noise_texture : repeat_enable, filter_linear;

uniform int MAX_STEPS = 60; // 最大步进次数
uniform float step_size = 0.1; // 每次步进的长度
uniform float max_distance = 100.0; // 最大反射距离
uniform float bias=3.0;

void fragment() {
    vec3 col = vec3(0.0); // 反射采样到的颜色，默认是黑色

    // 从深度纹理获取当前像素的深度值
    float depth = textureLod(depth_texture, SCREEN_UV, 0.0).r;

    // 将屏幕坐标转换为摄像机空间坐标
    vec4 camera_space_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
    vec3 pixel_position = camera_space_pos.xyz / camera_space_pos.w; // 摄像机空间中的像素位置

    // 获取法线和粗糙度
    vec4 normal_roughness = texture(normal_roughness_texture, SCREEN_UV);
    vec3 normal = normalize(normal_roughness.xyz * 2.0 - 1.0); // 法线在[-1, 1]范围内
    float roughness = normal_roughness.w;

    // 摄像机视线方向
    vec3 view_dir = normalize(pixel_position);

    // 计算反射方向
    vec3 reflect_dir = reflect(view_dir, normal);

    // 使用噪声和粗糙度扰动反射方向
    vec3 noise = texture(noise_texture, SCREEN_UV/vec2(.1)).rgb*vec3(2.0)-vec3(1.4);
    reflect_dir = normalize(mix(reflect_dir, reflect_dir + noise * roughness, roughness));

    // 初始化步进，反射方向的步进大小
    vec3 ray_pos = pixel_position; // 光线起点为像素位置
    vec3 one_step = reflect_dir * step_size; // 每一步的移动距离

    for (int i = 0; i < MAX_STEPS; i++) {
        ray_pos += one_step; // 沿反射方向步进

        // 将摄像机空间坐标转换回屏幕空间
        vec4 clip_pos = PROJECTION_MATRIX * vec4(ray_pos, 1.0);
        vec2 screen_pos = clip_pos.xy / clip_pos.w * 0.5 + 0.5;

        // 检查光线是否越界
        if (screen_pos.x < 0.0 || screen_pos.x > 1.0 || screen_pos.y < 0.0 || screen_pos.y > 1.0) {
            break; // 光线超出屏幕范围时停止步进
        }

        // 从深度纹理获取当前步进点的深度
        float scene_depth = textureLod(depth_texture, screen_pos, 0.0).r;

        // 将深度值转换回摄像机空间
        vec4 projected_pos = INV_PROJECTION_MATRIX * vec4(screen_pos * 2.0 - 1.0, scene_depth, 1.0);
        vec3 scene_position = projected_pos.xyz / projected_pos.w;

        // 如果步进的光线位置比当前深度值靠近摄像机，说明碰撞到了几何体
        if (length(scene_position) < length(ray_pos)) {
			if(abs(ray_pos.z-scene_position.z)<step_size*bias){//判断是否在反射物体的背面，3是一个bias，用于修复缝隙
            vec4 hit_color = texture(screen_texture, screen_pos);
            col = hit_color.rgb; // 采样颜色
			}
            break; // 停止步进
        }

        // 如果光线步进距离超过最大反射距离，则停止
        if (length(ray_pos) > max_distance) {
            break;
        }
    }
	if(depth>0.0){
		depth=1.0;
	}
    // 如果没有找到反射，默认使用黑色（或其他颜色）
    ALBEDO = texture(screen_texture,SCREEN_UV).xyz+col*vec3(depth)*vec3(1.0-roughness);
}
