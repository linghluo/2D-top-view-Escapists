shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

uniform float alertness_visual = 0.0;
uniform float max_alertness = 120.0;
uniform float threshold1 = 40.0; // 橙色
uniform float threshold2 = 70.0; // 红色+抖动

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 center = vec2(0.5);

    float level = clamp(alertness_visual / max_alertness, 0.0, 1.0);
    vec4 base_color = texture(SCREEN_TEXTURE, uv);

    // 调整后的扰动
    vec2 shake_offset = vec2(0.0);
    if (level > threshold2 / max_alertness) {
        float shake_amt = 0.0005; // 大幅度降低抖动量
        float pulse = abs(sin(TIME * 2.0)); // 抖动强度脉冲
        float dist_from_center = distance(uv, center);
        float shake_strength = smoothstep(0.5, 0.7, dist_from_center); // 中心轻微抖动，边缘较强

        shake_offset = vec2(
            sin(TIME * 15.0 + uv.y * 100.0),
            cos(TIME * 10.0 + uv.x * 80.0)
        ) * shake_amt * shake_strength * pulse;
    }

    vec4 shaken_color = texture(SCREEN_TEXTURE, uv + shake_offset);
    vec3 final_color = shaken_color.rgb;

    // 边缘感应
    float dist = distance(uv, center);
    float edge = smoothstep(0.5, 0.7, dist);
    float edge_alpha = 0.0;

    vec3 edge_tint = vec3(0.0);

    if (level > threshold2 / max_alertness) {
        edge_tint = vec3(1.0, 0.1, 0.1);
        edge_alpha = 0.4 * abs(sin(TIME * 6.0));
    } else if (level > threshold1 / max_alertness) {
        edge_tint = vec3(1.0, 0.5, 0.1);
        edge_alpha = 0.25;
    }

    final_color = mix(final_color, edge_tint, edge_alpha * edge);

    COLOR = vec4(final_color, 1.0);
}
