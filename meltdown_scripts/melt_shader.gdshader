shader_type spatial;

uniform float melt_amount : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D albedo_tex; // No hint

void fragment() {
    vec2 uv = UV;
    uv.y += melt_amount * 0.3;

    // 'texture()' works with sampler2D
    ALBEDO = texture(albedo_tex, uv).rgb;
    ALPHA = 1.0;
}
