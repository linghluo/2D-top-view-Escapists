shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 fill_color : source_color = vec4(0.0, 0.0, 0.0, 0.5); // 灰色背景
uniform vec4 border_color : source_color = vec4(1.0, 0.84, 0.0, 1.0); // 金色边框
uniform float border_width = 3.0;
uniform float glow_size = 2.0;
uniform vec2 screen_size = vec2(400.0, 100.0);

void fragment() {
    vec2 pixel_coord = UV * screen_size;

    float dist_left = pixel_coord.x;
    float dist_right = screen_size.x - pixel_coord.x;
    float dist_top = pixel_coord.y;
    float dist_bottom = screen_size.y - pixel_coord.y;

    float min_dist = min(min(dist_left, dist_right), min(dist_top, dist_bottom));
    float border_mask = smoothstep(border_width + 0.5, border_width - 0.5, min_dist);
    float glow_mask = smoothstep(border_width + glow_size, border_width, min_dist);

    vec4 color = fill_color;

    color += border_color * glow_mask * 0.4;
    color = mix(color, border_color, border_mask);

    COLOR = color;
}
