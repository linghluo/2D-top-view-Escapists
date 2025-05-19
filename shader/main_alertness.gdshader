shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

uniform float alertness_visual = 0.0;
uniform float max_alertness = 120.0;
uniform float threshold1 = 40.0; // 橙色
uniform float threshold2 = 70.0; // 红色+抖动

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 screen_size = vec2(textureSize(SCREEN_TEXTURE, 0));
    vec2 center = vec2(0.5);

    float level = clamp(alertness_visual / max_alertness, 0.0, 1.0);
    vec4 base_color = texture(SCREEN_TEXTURE, uv);

    // 扰动
    vec2 shake_offset = vec2(0.0);
    if (level > threshold2 / max_alertness) {
        float shake_amt = 0.002; // 轻微抖动
        shake_offset = vec2(
            sin(TIME * 60.0 + uv.y * 300.0),
            cos(TIME * 45.0 + uv.x * 250.0)
        ) * shake_amt;
    }

    vec4 shaken_color = texture(SCREEN_TEXTURE, uv + shake_offset);
    vec3 final_color = shaken_color.rgb;

    // 边缘感应
    float dist = distance(uv, center);
    float edge = smoothstep(0.5, 0.7, dist);
    float edge_alpha = 0.0;

    vec3 edge_tint = vec3(0.0);

    if (level > threshold2 / max_alertness) {
        // 红色闪烁边缘
        edge_tint = vec3(1.0, 0.1, 0.1);
        edge_alpha = 0.4 * abs(sin(TIME * 6.0));
    } else if (level > threshold1 / max_alertness) {
        // 橙色稳定边缘
        edge_tint = vec3(1.0, 0.5, 0.1);
        edge_alpha = 0.25;
    }

    final_color = mix(final_color, edge_tint, edge_alpha * edge);

    COLOR = vec4(final_color, 1.0);
}
