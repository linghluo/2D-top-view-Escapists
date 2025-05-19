shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float edge_threshold = 0.25;
uniform vec4 base_edge_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float edge_thickness = 3.0;
uniform float jitter_strength = 10.0;
uniform float noise_speed = 2.0;
uniform float pixel_noise_amount = 5;

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

void fragment() {
    vec2 screen_size = vec2(textureSize(SCREEN_TEXTURE, 0));
    vec2 uv = SCREEN_UV;

    // 加强波动晃动幅度
    float wave = sin(TIME * 3.5 + uv.y * 80.0) * jitter_strength / screen_size.x;
    float wave_y = cos(TIME * 4.0 + uv.x * 90.0) * jitter_strength / screen_size.y;
    uv += vec2(wave, wave_y);

    float noise = (fract(sin(dot(uv * TIME * noise_speed, vec2(12.9898,78.233))) * 43758.5453) - 0.5) * pixel_noise_amount;
    uv += vec2(noise / screen_size.x, noise / screen_size.y);

    float dx = edge_thickness / screen_size.x;
    float dy = edge_thickness / screen_size.y;

    vec3 c  = texture(SCREEN_TEXTURE, uv).rgb;
    vec3 hsv_c  = rgb2hsv(c);

    vec3 neighbors[8];
    neighbors[0] = rgb2hsv(texture(SCREEN_TEXTURE, uv + vec2(-dx, -dy)).rgb);
    neighbors[1] = rgb2hsv(texture(SCREEN_TEXTURE, uv + vec2(0.0, -dy)).rgb);
    neighbors[2] = rgb2hsv(texture(SCREEN_TEXTURE, uv + vec2(dx, -dy)).rgb);
    neighbors[3] = rgb2hsv(texture(SCREEN_TEXTURE, uv + vec2(-dx, 0.0)).rgb);
    neighbors[4] = rgb2hsv(texture(SCREEN_TEXTURE, uv + vec2(dx, 0.0)).rgb);
    neighbors[5] = rgb2hsv(texture(SCREEN_TEXTURE, uv + vec2(-dx, dy)).rgb);
    neighbors[6] = rgb2hsv(texture(SCREEN_TEXTURE, uv + vec2(0.0, dy)).rgb);
    neighbors[7] = rgb2hsv(texture(SCREEN_TEXTURE, uv + vec2(dx, dy)).rgb);

    float diff = 0.0;
    float weight_h = 0.5;
    float weight_s = 0.3;
    float weight_v = 0.2;

    for (int i = 0; i < 8; i++) {
        float dh = hue_diff(hsv_c.x, neighbors[i].x);
        float ds = abs(hsv_c.y - neighbors[i].y);
        float dv = abs(hsv_c.z - neighbors[i].z);
        diff += weight_h * dh + weight_s * ds + weight_v * dv;
    }

    float brightness_factor = smoothstep(0.0, 0.4, hsv_c.z);
    float edge_strength = smoothstep(edge_threshold, edge_threshold + 0.1, diff) * brightness_factor;

    vec4 base_col = texture(SCREEN_TEXTURE, uv);

    vec3 animated_edge_color = base_edge_color.rgb + 0.1 * sin(TIME * 3.0 + vec3(uv * 15.0, 0.0));
    animated_edge_color = clamp(animated_edge_color, 0.0, 1.0);

    COLOR = mix(base_col, vec4(animated_edge_color, 1.0), edge_strength);
}
