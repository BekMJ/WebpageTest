shader_type spatial;
render_mode unshaded; // if you want it unlit

uniform float melt_amount : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D albedo_tex;

// Define your own offset/scale uniforms
uniform vec2 uv_offset = vec2(0.0, 0.0);
uniform vec2 uv_scale = vec2(1.0, 1.0);

void fragment() {
    // Apply your custom offset and scale
    vec2 uv = UV * uv_scale + uv_offset;
    
    // Then do meltdown shift
    uv.y += melt_amount * 0.3;

    ALBEDO = texture(albedo_tex, uv).rgb;
    ALPHA = 1.0;
}
