shader_type spatial;

uniform float melt_strength : hint_range(0.0, 1.0) = 0.0;

void vertex() {
    // Distort the Y coordinate
    VERT.y -= sin(VERT.x * 5.0 + TIME) * 0.1 * melt_strength;
}

void fragment() {
    ALBEDO = vec3(1.0, 1.0, 1.0);
}
