shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float edge_threshold = 0.25;
uniform vec4 base_edge_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float edge_thickness = 3.0;
uniform float jitter_strength = 10.0;
uniform float noise_speed = 2.0;
uniform float pixel_noise_amount = 5.0;

vec3 rgb2hsv(vec3 c) {
    float maxc = max(c.r, max(c.g, c.b));
    float minc = min(c.r, min(c.g, c.b));
    float delta = maxc - minc;

    float h = 0.0;
    if (delta > 0.0001) {
        if (maxc == c.r) {
            h = mod((c.g - c.b) / delta, 6.0);
        } else if (maxc == c.g) {
            h = ((c.b - c.r) / delta) + 2.0;
        } else {
            h = ((c.r - c.g) / delta) + 4.0;
        }
        h /= 6.0;
        if (h < 0.0) h += 1.0;
    }
    float s = maxc < 0.0001 ? 0.0 : delta / maxc;
    float v = maxc;
    return vec3(h, s, v);
}

float hue_diff(float h1, float h2) {
    float d = abs(h1 - h2);
    return min(d, 1.0 - d);
}

float edge_detect(vec2 uv, float thickness) {
    vec2 screen_size = vec2(textureSize(SCREEN_TEXTURE, 0));
    float dx = thickness / screen_size.x;
    float dy = thickness / screen_size.y;

    vec3 c = rgb2hsv(texture(SCREEN_TEXTURE, uv).rgb);
    float diff = 0.0;

    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            if (i == 0 && j == 0) continue;
            vec3 n = rgb2hsv(texture(SCREEN_TEXTURE, uv + vec2(float(i) * dx, float(j) * dy)).rgb);
            float dh = hue_diff(c.x, n.x);
            float ds = abs(c.y - n.y);
            float dv = abs(c.z - n.z);
            diff += 0.5 * dh + 0.3 * ds + 0.2 * dv;
        }
    }

    // 直接返回是否超过阈值（0 或 1）
    return diff > edge_threshold ? 1.0 : 0.0;
}

void fragment() {
    vec2 screen_size = vec2(textureSize(SCREEN_TEXTURE, 0));
    vec2 uv = SCREEN_UV;

    // 仅在高警戒时启用抖动逻辑，这里始终保留抖动，但如果不想要可设为 0
    float wave = sin(TIME * 3.5 + uv.y * 80.0) * jitter_strength / screen_size.x;
    float wave_y = cos(TIME * 4.0 + uv.x * 90.0) * jitter_strength / screen_size.y;
    uv += vec2(wave, wave_y);

    float noise = (fract(sin(dot(uv * TIME * noise_speed, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * pixel_noise_amount;
    uv += vec2(noise / screen_size.x, noise / screen_size.y);

    // 读取原始颜色
    vec4 base_col = texture(SCREEN_TEXTURE, uv);

    // 检测边缘（0.0 或 1.0）
    float is_edge = edge_detect(uv, edge_thickness);

    // 如果是边缘像素，就输出黑色；否则保持原色
    if (is_edge > 0.5) {
        COLOR = base_edge_color;
    } else {
        COLOR = base_col;
    }
}
