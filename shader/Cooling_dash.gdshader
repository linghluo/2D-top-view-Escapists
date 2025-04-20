shader_type canvas_item;
render_mode blend_add, unshaded;

uniform float progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	// 先亮后暗
	float brightness = sin(progress * 3.14159); // pi

	// 乘以亮度
	COLOR.rgb = tex.rgb * brightness;

	// 透明度随亮度变化
	COLOR.a = tex.a * brightness;
}
