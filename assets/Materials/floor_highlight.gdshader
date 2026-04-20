shader_type canvas_item;

//uniform sampler2D overlay_texture: repeat_enable, filter_nearest;
uniform sampler2D border_texture: repeat_enable, filter_nearest;
uniform vec4 color : source_color;
uniform vec4 border_color : source_color;
uniform float pulse_speed = 1.0;
uniform bool is_pulsing = false;
uniform float opacity = 0.4;
uniform float border_opacity = 0.8;
instance uniform bool needs_top_border;
instance uniform bool needs_right_border;
instance uniform bool needs_bottom_border;
instance uniform bool needs_left_border;

varying vec2 vertex_position;

void vertex() {
	vertex_position.xy = VERTEX;
}

void fragment() {
	float pulse_factor = 1.0;
	if(is_pulsing){
	 	pulse_factor = pow(sin(TIME * pulse_speed), 2);	
	}
	vec4 tex_color = texture(TEXTURE, UV * 1.0f);
	vec4 shifted_color = tex_color * color * opacity;
	
	if(needs_top_border){
		vec4 tex_border_color = texture(border_texture, UV);
		if(tex_border_color.a > 0.0) {
			shifted_color = tex_border_color * border_color * border_opacity;	
		}
	}
	if(needs_bottom_border){
		vec4 tex_border_color = texture(border_texture, vec2(UV.x, 1.0 - UV.y));
		if(tex_border_color.a > 0.0) {
			shifted_color = tex_border_color * border_color * border_opacity;;	
		}
	}
	if(needs_right_border){
		vec4 tex_border_color = texture(border_texture, vec2(-UV.y, 1.0 - UV.x));
		if(tex_border_color.a > 0.0) {
			shifted_color = tex_border_color * border_color * border_opacity;;	
		}
	}
	if(needs_left_border){
		vec4 tex_border_color = texture(border_texture, vec2(-UV.y, UV.x));
		if(tex_border_color.a > 0.0) {
			shifted_color = tex_border_color * border_color * border_opacity;;	
		}
	}
	
	COLOR = vec4(
	shifted_color.xyz, 
	shifted_color.a * pulse_factor);
    }