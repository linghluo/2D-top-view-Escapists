shader_type canvas_item;

render_mode blend_add, unshaded;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 slash_color = vec4(1.0, 0.2, 0.2, 0.8);
uniform float arc_angle = 3.14159;
uniform float softness = 0.2;

void fragment() {
    vec2 uv = UV - vec2(0.5);
    float angle = atan(uv.y, uv.x);
    if (angle < 0.0) angle += 6.28318;

    float start_angle = progress * 6.28318;
    float end_angle = start_angle + arc_angle;

    bool in_arc = false;
    if (end_angle < 6.28318) {
        in_arc = (angle >= start_angle) && (angle <= end_angle);
    } else {
        in_arc = (angle >= start_angle) || (angle <= (end_angle - 6.28318));
    }

    float dist = length(uv);
    float radius_min = 0.3;
    float radius_max = 0.7;
    float radius_alpha = smoothstep(radius_max, radius_max - softness, dist) * (1.0 - smoothstep(radius_min, radius_min + softness, dist));

    float alpha = in_arc ? radius_alpha : 0.0;

    vec4 col = slash_color * alpha;
    col.rgb *= col.a * 2.5;

    COLOR = col;
}
