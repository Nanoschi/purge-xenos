shader_type canvas_item;

uniform vec3 color : source_color;
uniform float pulse_speed = 3.0;

float get_edge_dist(vec2 uv, float radius) {
	return min(max(distance(uv, vec2(4.0, 4.0)) - radius, 0.0), 1.0);
}

void fragment() {
	float pulse = pow(sin(TIME * pulse_speed), 2);
	float radius = 2.0 + pulse * 0.4;
	float center_dist = distance(UV, vec2(4.0, 4.0));
	COLOR.xyz = color;
	float alpha = 1.0 - get_edge_dist(UV, radius);
	COLOR.a = pow(alpha, 3);
	
	if (distance(UV, vec2(4.0, 4.0)) > 1.0) {
		COLOR.xyz *= 0.9;
	}
}
