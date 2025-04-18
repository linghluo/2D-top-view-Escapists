shader_type canvas_item;
render_mode blend_add, unshaded;

uniform float time : hint_range(0.0, 1.0);
uniform vec4 glow_color : source_color = vec4(1.5, 0.8, 2.0, 0.5); // 颜色及其亮度

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    float lif = 1.0 - time;
    vec3 final_color = tex_color.rgb * lif * 0.6 + glow_color.rgb * lif;

    COLOR = vec4(final_color, tex_color.a * lif);
}
