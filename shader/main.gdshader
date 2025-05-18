shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float edge_threshold = 0.2;
uniform vec4 base_edge_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float edge_thickness = 1.5;
uniform float jitter_strength = 2.0;
uniform float noise_speed = 1.5;
uniform float pixel_noise_amount = 0.03;

float rand(vec2 co) {
	return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float color_diff(vec3 a, vec3 b) {
	return length(a - b);
}

void fragment() {
	vec2 screen_size = vec2(textureSize(SCREEN_TEXTURE, 0));
	vec2 uv = SCREEN_UV;

	// 波动 噪声
	float wave = sin(TIME * 2.0 + uv.y * 50.0) * jitter_strength / screen_size.x;
	float wave_y = cos(TIME * 2.5 + uv.x * 60.0) * jitter_strength / screen_size.y;
	uv += vec2(wave, wave_y);

	float noise = (rand(uv * TIME * noise_speed) - 0.5) * pixel_noise_amount;
	uv += vec2(noise / screen_size.x, noise / screen_size.y);

	float dx = edge_thickness / screen_size.x;
	float dy = edge_thickness / screen_size.y;

	vec3 c  = texture(SCREEN_TEXTURE, uv).rgb;
	vec3 tl = texture(SCREEN_TEXTURE, uv + vec2(-dx, -dy)).rgb;
	vec3  t = texture(SCREEN_TEXTURE, uv + vec2( 0.0, -dy)).rgb;
	vec3 tr = texture(SCREEN_TEXTURE, uv + vec2( dx, -dy)).rgb;
	vec3 l  = texture(SCREEN_TEXTURE, uv + vec2(-dx,  0.0)).rgb;
	vec3 r  = texture(SCREEN_TEXTURE, uv + vec2( dx,  0.0)).rgb;
	vec3 bl = texture(SCREEN_TEXTURE, uv + vec2(-dx,  dy)).rgb;
	vec3  b = texture(SCREEN_TEXTURE, uv + vec2( 0.0,  dy)).rgb;
	vec3 br = texture(SCREEN_TEXTURE, uv + vec2( dx,  dy)).rgb;

	float diff =
		color_diff(c, tl) + color_diff(c, t) + color_diff(c, tr) +
		color_diff(c, l) + color_diff(c, r) +
		color_diff(c, bl) + color_diff(c, b) + color_diff(c, br);

	vec4 base_col = texture(SCREEN_TEXTURE, uv);

	// 动态边缘颜色检测
	vec3 animated_edge_color = base_edge_color.rgb + 0.05 * sin(TIME + vec3(uv * 10.0, 0.0));
	animated_edge_color = clamp(animated_edge_color, 0.0, 1.0);

	if (diff > edge_threshold) {
		COLOR = vec4(animated_edge_color, 1.0);
	} else {
		COLOR = base_col;
	}
}
