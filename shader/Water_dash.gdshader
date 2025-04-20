shader_type canvas_item;
render_mode blend_add, unshaded;

uniform float progress : hint_range(0.0, 1.0);
uniform vec4 tint_color : source_color = vec4(1.0);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	float alpha = 1.0 - progress;

	COLOR = tex_color * tint_color;
	COLOR.a *= alpha;
}
