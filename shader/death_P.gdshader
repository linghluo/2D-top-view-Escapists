shader_type canvas_item;
render_mode unshaded;

uniform float glow_strength = 2.0;

void fragment() {
    vec4 col = COLOR;

    col.rgb *= glow_strength;

    COLOR = col;
}
