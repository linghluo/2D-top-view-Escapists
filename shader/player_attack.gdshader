shader_type canvas_item;

render_mode blend_add, unshaded;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 slash_color = vec4(1.0, 0.8, 0.2, 0.9);
uniform float arc_angle = 1.57; // 约90度弧
uniform float softness = 0.1;

void fragment() {
    vec2 uv = UV - vec2(0.5);

    // 计算极坐标
    float angle = atan(uv.y, uv.x);
    if (angle < 0.0) angle += 6.28318;

    float dist = length(uv);

    // 旋转的起始角度和结束角度
    float start_angle = progress * 6.28318;
    float end_angle = start_angle + arc_angle;

    // 判断点是否在刀光扇形内（考虑循环角度）
    bool in_arc = false;
    if (end_angle < 6.28318) {
        in_arc = (angle >= start_angle) && (angle <= end_angle);
    } else {
        in_arc = (angle >= start_angle) || (angle <= (end_angle - 6.28318));
    }

    if (!in_arc) {
        discard;
    }

    // 角度内相对进度，0~1表示从起点到终点的角度位置
    float arc_pos = 0.0;
    if (end_angle < 6.28318) {
        arc_pos = (angle - start_angle) / arc_angle;
    } else {
        arc_pos = (angle >= start_angle) ?
            (angle - start_angle) / arc_angle :
            (angle + 6.28318 - start_angle) / arc_angle;
    }

    // 计算径向alpha，用来形成刀锋的厚度和透明度曲线
    // 中心距离靠近0时透明，靠近某范围内达到高亮，然后远端透明
    float radius_inner = 0.3;
    float radius_peak = 0.5;
    float radius_outer = 0.7;

    float alpha_radial = smoothstep(radius_inner, radius_peak, dist) * (1.0 - smoothstep(radius_peak, radius_outer, dist));

    // 角度方向alpha控制，形成尖锐“尾部”拖尾感
    // arc_pos越靠近0，alpha越大，越靠近1渐隐
    float alpha_angular = smoothstep(0.8, 0.0, arc_pos);

    // 复合alpha，形成非均匀光刃
    float alpha = alpha_radial * alpha_angular;

    vec4 col = slash_color * alpha;
    col.rgb *= col.a * 3.0; // 放大发光效果

    COLOR = col;
}
