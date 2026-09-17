shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 0.85, 0.3, 1.0);
uniform float glow_strength = 2.0;
uniform float pulse_speed = 3.0;
uniform float pulse_amount = 0.25;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    // Efek berkedip
    float pulse = 1.0 + sin(TIME * pulse_speed) * pulse_amount;

    // Warna dasar texture
    vec3 color = tex.rgb * glow_color.rgb;

    // Tambahkan intensitas cahaya
    color *= glow_strength * pulse;

    COLOR = vec4(color, tex.a);
}