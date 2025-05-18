shader_type canvas_item;
render_mode blend_add, unshaded;

uniform float progress : hint_range(0.0, 1.0);
uniform vec4 tint_color : source_color = vec4(0.0, 0.8, 1.0, 1.0); // 发光主色

// 扩散最大距离，单位是UV坐标偏移
uniform float max_glow_radius : hint_range(0.01, 0.1) = 0.05;
// 采样点数，采样越多越平滑但成本也高
const int sample_count = 8;

void fragment() {
    vec4 base = texture(TEXTURE, UV);
    vec4 glow = vec4(0.0);

    // 随着 progress 越大，扩散越远且越暗
    float radius = max_glow_radius * progress;
    float intensity = 1.0 - progress;

    // 8个方向采样偏移
    vec2 offsets[sample_count] = vec2[](
        vec2(1.0, 0.0),
        vec2(-1.0, 0.0),
        vec2(0.0, 1.0),
        vec2(0.0, -1.0),
        vec2(0.7, 0.7),
        vec2(-0.7, 0.7),
        vec2(0.7, -0.7),
        vec2(-0.7, -0.7)
    );

    for (int i = 0; i < sample_count; i++) {
        vec2 offset = offsets[i] * radius;
        vec4 sample = texture(TEXTURE, UV + offset);
        // 用alpha和颜色乘，发光基于形状alpha
        glow += sample * tint_color * sample.a;
    }

    glow /= float(sample_count);
    glow.a *= intensity;  // 扩散越大越暗

    // 最终颜色：原图 + 发光部分（叠加，注意材质blend mode设Add）
    COLOR = base + glow;
}
