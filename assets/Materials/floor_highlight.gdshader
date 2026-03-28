shader_type canvas_item;

uniform sampler2D overlay_texture: repeat_enable, filter_nearest;
uniform vec4 color : source_color;
uniform float pulse_speed = 1.0;
uniform float opacity = 0.4;

varying vec2 vertex_position;

void vertex() {
	vertex_position.xy = VERTEX;
}

float get_falloff_factor(vec2 position) {
	vec2 center_dist = vec2(
		abs(position.x) - 5.1,
		abs(position.y) - 5.1
	);
	
	float max_dist = max(center_dist.x, center_dist.y);
	
	return pow(1.0 / (max_dist * 1.3), 1.5);
}

void fragment() {
	float pulse_factor = pow(sin(TIME * pulse_speed), 2);
	vec4 tex_color = texture(overlay_texture, UV * 3.0f);
	vec4 shifted_color = tex_color * color;
	COLOR = vec4(
	shifted_color.xyz, 
	shifted_color.a * pulse_factor * opacity * get_falloff_factor(vertex_position));
    }